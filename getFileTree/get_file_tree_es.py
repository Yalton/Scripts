import os
import argparse
import time
import logging
from elasticsearch import Elasticsearch
from elasticsearch.helpers import bulk
from math import log, floor
from datetime import datetime
from concurrent.futures import ProcessPoolExecutor
from concurrent.futures import as_completed

def setup_logging(directory):
    directory_name = os.path.basename(os.path.normpath(directory))
    log_file = f"logs/{directory_name}.log"
    logging.basicConfig(filename=log_file, level=logging.INFO,
                        format="%(asctime)s - %(levelname)s: %(message)s")
    logging.getLogger().addHandler(logging.StreamHandler())


def convert_size(size_bytes):
    if size_bytes == 0:
        return "0B", 0
    size_name = ("B", "KB", "MB", "GB", "TB")
    i = int(floor(log(size_bytes, 1024)))
    p = pow(1024, i)
    s = round(size_bytes / p, 2)
    return f"{s} {size_name[i]}", size_bytes

def human_readable_time(seconds):
    if seconds < 1:
        return f"{seconds * 1000:.2f} ms"
    elif seconds < 60:
        return f"{seconds:.2f} s"
    elif seconds < 3600:
        return f"{seconds / 60:.2f} min"
    else:
        return f"{seconds / 3600:.2f} hr"

memoized_sizes = {}
def get_directory_size(path):
    if path in memoized_sizes:
        return memoized_sizes[path]
    total = 0
    for dirpath, dirnames, filenames in os.walk(path):
        for file in filenames:
            file_path = os.path.join(dirpath, file)
            if not os.path.islink(file_path):
                total += os.path.getsize(file_path)
    memoized_sizes[path] = total
    return total

def get_directory_data(directory, max_depth=5):
    current_time = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    entries_list = []
    
    # Added a depth control
    depth = directory.count(os.sep)
    if depth > max_depth:
        return entries_list

    for dirpath, dirnames, filenames in os.walk(directory):
        for dirname in dirnames:
            path = os.path.join(dirpath, dirname)
            size_readable, size_bytes = convert_size(get_directory_size(path))
            
            # Filtering directories with size < 10MB
            # if size_bytes < 10_485_760:  # 10 MB in bytes
            #     continue
            
            entries_list.append({
                "path": path,
                "name": dirname,
                "size_readable": size_readable,
                "size_bytes": size_bytes,
                "type": "directory",
                "parent_directory": dirpath,
                "scrape_timestamp": current_time
            })
        for filename in filenames:
            path = os.path.join(dirpath, filename)
            
            try:
                size_readable, size_bytes = convert_size(os.path.getsize(path))
                
                # Filtering files with size < 10MB
                # if size_bytes < 10_485_760:  # 10 MB in bytes
                #     continue
                
                entries_list.append({
                    "path": path,
                    "name": filename,
                    "size_readable": size_readable,
                    "size_bytes": size_bytes,
                    "type": "file",
                    "parent_directory": dirpath,
                    "scrape_timestamp": current_time
                })
            except FileNotFoundError:
                continue  # Just skip if file not found

    # Sort the data by size in descending order before returning
    return sorted(entries_list, key=lambda x: x['size_bytes'], reverse=True)

def parallel_directory_walker(root_directory, max_workers=4):
    directories = [os.path.join(root_directory, dir_name) for dir_name in os.listdir(root_directory) if os.path.isdir(os.path.join(root_directory, dir_name))]
    all_entries = []
    
    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(get_directory_data, dir_path): dir_path for dir_path in directories}
        
        for future in as_completed(futures):
            all_entries.extend(future.result())
    
    return all_entries

def index_exists(es, index_name):
    return es.indices.exists(index=index_name)

def create_index_with_mapping(es, index_name, mapping):
    return es.indices.create(index=index_name, body=mapping)

def generate_mapping_from_data(data):
    mapping = {}
    if isinstance(data, dict):
        properties = {}
        for key, value in data.items():
            properties[key] = generate_mapping_from_data(value)
        mapping["properties"] = properties
    elif isinstance(data, str):
        try:
            datetime.strptime(data, '%Y-%m-%d %H:%M:%S')
            return {"type": "date", "format": "yyyy-MM-dd HH:mm:ss"}
        except ValueError:
            return {"type": "text"}
    else:
        return {"type": "text"}
    return mapping

def add_to_alias(es, index_name, alias_name):
    if not es.indices.exists_alias(name=alias_name):
        es.indices.put_alias(index=index_name, name=alias_name)
    else:
        alias_data = es.indices.get_alias(name=alias_name)
        if index_name not in alias_data:
            es.indices.update_aliases(body={
                "actions": [
                    {"add": {"index": index_name, "alias": alias_name}}
                ]
            })

def get_alias_name_from_directory(directory):
    return os.path.basename(os.path.normpath(directory))

def delete_index_if_exists(es, index_name):
    if index_exists(es, index_name):
        es.indices.delete(index=index_name)

def upload_to_elasticsearch(directory, data_list):
    es = Elasticsearch(
        [{'host': '192.168.50.99', 'port': 9200, 'scheme': 'http'}],
        basic_auth=('elastic', 'LRvs=smuDyD1b1KcUhYs')
    )
    index_name = f"truenas_directory_data_{get_alias_name_from_directory(directory).lower()}"
    root_alias_name = "truenas_directory_data"
    
    # Delete the index if it already exists
    delete_index_if_exists(es, index_name)
    
    if not index_exists(es, index_name):
        mapping = {
            "mappings": generate_mapping_from_data(data_list[0] if data_list else {})
        }
        create_index_with_mapping(es, index_name, mapping)
    
    # Prepare data for bulk indexing
    actions = [
        {
            "_index": index_name,
            "_source": entry
        }
        for entry in data_list
    ]
    
    # Use the bulk API
    bulk(es, actions)
    
    add_to_alias(es, index_name, root_alias_name)
    add_to_alias(es, index_name, get_alias_name_from_directory(directory))


def main():
    parser = argparse.ArgumentParser(description='Scan a directory and create a flat list of file data.')
    parser.add_argument('directory', type=str, help='The directory to scan')
    args = parser.parse_args()
    setup_logging(args.directory)
    start_time = time.time()
    flat_data = parallel_directory_walker(args.directory)
    
    # Sort by size and slice to keep only top 10,000 entries
    flat_data = sorted(flat_data, key=lambda x: x['size_bytes'], reverse=True)[:10000]
    
    logging.info(f"{args.directory} has been scanned, uploading data...")
    upload_to_elasticsearch(args.directory, flat_data)
    elapsed_time = time.time() - start_time
    logging.info(f"Data for {args.directory} uploaded to Elasticsearch.")
    logging.info(f"Total scanning time: {human_readable_time(elapsed_time)}")




if __name__ == "__main__":
    main()