import os
import subprocess
import argparse

def getArgs(): 

    parser = argparse.ArgumentParser()
    parser.add_argument('--path', '-p', type=str, required=True)
    return parser.parse_args()

def main():
    args = getArgs()
    mypath = args.path
    filenames = os.listdir(mypath)

    #print (filenames)

    for url in filenames: 
        url = 'https://' + url

    for url in filenames: 
        print(f"""wget -q --recursive --html-extension --page-requisites --convert-links {url} -P {mypath}""")
        #os.system(f"""wget -q --recursive --html-extension --page-requisites --convert-links {url} -P {mypath}""")
        subprocess.Popen(f"""wget -q --recursive --html-extension --page-requisites --convert-links {url} -P {mypath}""", shell=True)

if __name__ == "__main__": 
    main()