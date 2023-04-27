import os
import sys
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor

def get_folder_size(folder):
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(folder):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            total_size += os.path.getsize(fp)
    return total_size

def process_directory(entry):
    if entry.is_dir():
        folder_size = get_folder_size(entry.path)
        size_in_gb = folder_size / (1024 * 1024 * 1024)
        return (entry.path, size_in_gb)
    return None

def tree_structure_size(base_path, prefix=''):
    results = []

    with ThreadPoolExecutor() as executor:
        folder_sizes = list(executor.map(process_directory, os.scandir(base_path)))

    for folder_size in folder_sizes:
        if folder_size is not None:
            folder_path, size_in_gb = folder_size
            results.append((folder_path, size_in_gb))
            results.extend(tree_structure_size(folder_path, prefix=prefix + '  '))

    return results

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: python folder_size_tree.py [directory]')
        sys.exit(1)

    base_directory = sys.argv[1]
    if not os.path.isdir(base_directory):
        print(f"Error: {base_directory} is not a valid directory.")
        sys.exit(1)

    log_filename = os.path.join(base_directory, 'folder_size_tree_log.txt')
    folder_sizes = tree_structure_size(base_directory)

    with open(log_filename, 'w') as log_file:
        log_file.write(f"Scan date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        log_file.write(f"Folder size tree for: {base_directory}\n\n")

        for folder_path, size_in_gb in folder_sizes:
            log_file.write(f"{folder_path}: {size_in_gb:.2f} GB\n")

    print(f"Folder size tree log saved at: {log_filename}")
