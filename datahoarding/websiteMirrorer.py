import os
import argparse

def getArgs(): 

    parser = argparse.ArgumentParser()
    parser.add_argument('--path', '-p', type=str, required=True)
    return parser.parse_args()

def main():
    args = getArgs()
    #mypath = "/mnt/nas/shared/DataHoard/Websites"
    mypath = args.path
    filenames = os.listdir(mypath)

    print (filenames)

    for url in filenames: 
        url = 'https://' + url

    for url in filenames: 
        os.system(f"""wget -q --recursive --html-extension --page-requisites --convert-links {url} -P {mypath}""")

if __name__ == "__main__": 
    main()