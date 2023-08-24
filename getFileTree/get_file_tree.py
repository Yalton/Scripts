import os
import json
import argparse
from math import log, floor

def convert_size(size_bytes):
    if size_bytes == 0:
        return "0B"
    size_name = ("B", "KB", "MB", "GB", "TB")
    i = int(floor(log(size_bytes, 1024)))
    p = pow(1024, i)
    s = round(size_bytes / p, 2)
    return f"{s} {size_name[i]}"

def get_files_tree(directory, depth=0, max_depth=6):
    if depth > max_depth:
        return None
    
    tree = []
    for entry in sorted(os.listdir(directory), key=lambda x: os.path.getsize(os.path.join(directory, x)), reverse=True):
        path = os.path.join(directory, entry)
        if os.path.isdir(path):
            subtree = get_files_tree(path, depth + 1, max_depth)
            if subtree:
                tree.append({"name": entry, "size": None, "children": subtree})
        else:
            size = convert_size(os.path.getsize(path))
            tree.append({"name": entry, "size": size, "children": None})
    
    return tree

def save_to_json(directory):
    tree = get_files_tree(directory)
    output_file = os.path.join(directory, 'file_tree.json')
    with open(output_file, 'w') as file:
        json.dump(tree, file)

def main():
    parser = argparse.ArgumentParser(description='Scan a directory and create a sorted tree of file sizes.')
    parser.add_argument('directory', type=str, help='The directory to scan')

    args = parser.parse_args()
    save_to_json(args.directory)

if __name__ == "__main__":
    main()
