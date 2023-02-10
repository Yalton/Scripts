import os


mypath = "/mnt/nas/shared/DataHoard/Websites"
filenames = os.listdir(mypath)

print (filenames)

for url in filenames: 
    url = 'https://' + url

for url in filenames: 
    os.system(f"""wget -q --recursive --html-extension --page-requisites --convert-links {url} -P {mypath}""")