#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display help message
display_help() {
    echo -e "${YELLOW}Usage:${NC} $0 [appimage_path] [icon_path] [program_name]"
    echo -e "${YELLOW}Install an AppImage and create a desktop entry.${NC}"
    echo
    echo -e "${BLUE}Arguments:${NC}"
    echo -e "  ${GREEN}appimage_path${NC}   Path to the AppImage file (absolute or relative)."
    echo -e "  ${GREEN}icon_path${NC}       Path to the icon file (absolute or relative)."
    echo -e "  ${GREEN}program_name${NC}    Name of the program."
    echo
    echo -e "${BLUE}Options:${NC}"
    echo -e "  ${GREEN}-h, --help${NC}      Display this help message."
}

# Function to determine if a path is absolute or relative
is_absolute_path() {
    case "$1" in
        /*) return 0 ;;
        *) return 1 ;;
    esac
}

# Check if the help argument is provided
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    display_help
    exit 0
fi

# Check if the required number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo -e "${RED}Error: Invalid number of arguments.${NC}"
    display_help
    exit 1
fi

# Accept arguments
appimage_path="$1"
icon_path="$2"
program_name="$3"

# Get the current working directory
current_dir=$(pwd)

# Set the absolute paths based on the input
if is_absolute_path "$appimage_path"; then
    absolute_appimage_path="$appimage_path"
else
    absolute_appimage_path="$current_dir/$appimage_path"
fi

if is_absolute_path "$icon_path"; then
    absolute_icon_path="$icon_path"
else
    absolute_icon_path="$current_dir/$icon_path"
fi

# Create directory in /opt/
opt_dir="/opt/$program_name"
sudo mkdir -p "$opt_dir"
echo -e "${GREEN}Created directory:${NC} $opt_dir"

# Copy AppImage and icon to the directory, overwriting if they exist
sudo cp -f "$absolute_appimage_path" "$opt_dir/"
echo -e "${GREEN}Copied AppImage to:${NC} $opt_dir/$(basename "$appimage_path")"
sudo cp -f "$absolute_icon_path" "$opt_dir/"
echo -e "${GREEN}Copied icon to:${NC} $opt_dir/$(basename "$icon_path")"

# Make the AppImage executable
sudo chmod +x "$opt_dir/$(basename "$appimage_path")"
echo -e "${GREEN}Made AppImage executable:${NC} $opt_dir/$(basename "$appimage_path")"

# Remove existing symlink if it exists
if [ -L "/usr/local/bin/$program_name" ]; then
    sudo rm "/usr/local/bin/$program_name"
    echo -e "${YELLOW}Removed existing symlink:${NC} /usr/local/bin/$program_name"
fi

# Create symlink in /usr/local/bin
sudo ln -s "$opt_dir/$(basename "$appimage_path")" "/usr/local/bin/$program_name"
echo -e "${GREEN}Created symlink:${NC} /usr/local/bin/$program_name"

echo "-------------------------------------------------------"

# Prompt user for desktop entry fields
echo -e "${BLUE}Enter the desktop entry type (Application, Link, Directory):${NC}"
read -p "Type: " type

echo -e "${BLUE}Enter a comment for the desktop entry:${NC}"
read -p "Comment: " comment

echo -e "${BLUE}Enter categories for the desktop entry (separated by semicolons):${NC}"
echo -e "${YELLOW}Valid categories:${NC} AudioVideo, Audio, Video, Development, Education, Game, Graphics, Network, Office, Science, Settings, System, Utility"
read -p "Categories: " categories

# Create desktop entry file, overwriting if it exists
desktop_file="$HOME/.local/share/applications/$program_name.desktop"
cat > "$desktop_file" <<EOL
[Desktop Entry]
Type=$type
Name=$program_name
Exec=/usr/local/bin/$program_name
Icon=$opt_dir/$(basename "$icon_path")
Comment=$comment
Terminal=false
Categories=$categories
EOL
echo -e "${GREEN}Created desktop entry file:${NC} $desktop_file"

# Make the desktop entry file executable
chmod +x "$desktop_file"
echo -e "${GREEN}Made desktop entry file executable:${NC} $desktop_file"

echo "-------------------------------------------------------"
echo -e "${GREEN}Installation completed successfully.${NC}"