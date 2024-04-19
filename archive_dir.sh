#!/bin/bash

# Set the subdirectory path
subdirectory="/mnt/truenas/Datahoard/Books/Non-Fiction/History"

# Change to the subdirectory
cd "$subdirectory"

# Loop through each item in the subdirectory
for item in *; do
    # Check if the item is a directory and not an archive
    if [ -d "$item" ] && [[ "$item" != *.tar.gz ]]; then
        directory_name="$item"
        
        echo "Archiving directory: $directory_name"
        
        # Create a tar.gz archive of the directory
        tar -czf "${directory_name}.tar.gz" "$directory_name"
        
        echo "Archive created: ${directory_name}.tar.gz"
        
        # Remove the unarchived directory
        rm -rf "$directory_name"
        
        echo "Unarchived directory removed: $directory_name"
        echo "---"
    fi
done

echo "Archiving process completed."