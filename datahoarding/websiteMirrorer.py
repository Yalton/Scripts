from os import walk


mypath = "/mnt/nas/shared/DataHoard/Websites"
filenames = next(walk(mypath), (None, None, []))[2]  # [] if no file
print (filenames)