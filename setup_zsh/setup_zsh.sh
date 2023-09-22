#!/bin/bash

#!/bin/bash
set -x

# Update and install zsh
sudo apt update
sudo apt install zsh -y

# Change the default shell to zsh
chsh -s $(which zsh)

# Install Oh My Zsh
echo "Y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Backup .bashrc and .zshrc
cp ~/.bashrc ~/.bashrc.backup
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.backup  # Check if .zshrc exists before copying

# Copy export lines from .bashrc to .zshrc
grep "^export " ~/.bashrc >> ~/.zshrc

# Edit .zshrc using nano
#nano ~/.zshrc

# Source .zshrc
source ~/.zshrc
