import os


mypath = "/mnt/nas/shared/DataHoard/Websites"
filenames = os.listdir(mypath)
# filenames = next(walk(mypath), (None, None, []))[2]  # [] if no file
print (filenames)