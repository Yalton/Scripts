import os


mypath = "/mnt/nas/shared/DataHoard/Websites"
filenames = os.listdir(mypath)

print (filenames)

for url in filenames: 
    url = 'https://' + url

for url in filenames: 
    os.system(f"""wget --recursive --html-extension --page-requisites --convert-links {url} -P {mypath}""")
    # wget.download(url, out=output_directory)