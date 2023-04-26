import os
import subprocess
import argparse
import time
from concurrent.futures import ThreadPoolExecutor

def getArgs():
    parser = argparse.ArgumentParser()
    parser.add_argument('--path', '-p', type=str, required=True)
    parser.add_argument('--delay', '-d', type=int, default=0, help="Delay between downloads in seconds")
    parser.add_argument('--workers', '-w', type=int, default=4, help="Number of parallel downloads")
    return parser.parse_args()

def download_website(url, original_name, mypath, delay):
    target_path = os.path.join(mypath, original_name)
    wget_command = f"""wget --mirror --convert-links --adjust-extension --page-requisites --no-parent -e robots=off --backup-converted=off --directory-prefix {mypath} {url}"""
    print(wget_command)
    time.sleep(delay)
    try:
        subprocess.check_output(wget_command, shell=True, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        print(f"Error downloading {url}: {e.output.decode('utf-8')}")

def main():
    args = getArgs()
    mypath = args.path
    delay = args.delay
    workers = args.workers
    filenames = os.listdir(mypath)

    # Remove "www." from the beginning of each URL
    cleaned_urls = ['https://' + url.replace('www.', '') for url in filenames]

    with ThreadPoolExecutor(max_workers=workers) as executor:
        for url, original_name in zip(cleaned_urls, filenames):
            executor.submit(download_website, url, original_name, mypath, delay)

if __name__ == "__main__":
    main()
