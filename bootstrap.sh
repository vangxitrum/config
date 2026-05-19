#!/bin/bash

# This script is a "one-liner" bootstrap for a fresh Ubuntu installation.
# It installs basic dependencies, clones the repository, and runs the initialization.

set -e

echo "=================================="
echo "Ubuntu Bootstrap & Config Setup"
echo "=================================="

# Update and install git/curl
sudo apt-get update
sudo apt-get install -y git curl

# Define target directory
TARGET_DIR="$HOME/setup/config"
mkdir -p "$HOME/setup"

# Clone the repository if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    echo "Cloning configuration repository..."
    git clone https://github.com/vangxitrum/config.git "$TARGET_DIR"
else
    echo "Configuration directory already exists, pulling latest changes..."
    cd "$TARGET_DIR" && git pull
fi

# Run the initialization
cd "$TARGET_DIR"
chmod +x ./init.sh ./scripts/*.sh
./init.sh

echo ""
echo "=================================="
echo "Bootstrap Complete!"
echo "Please restart your computer to apply all changes (especially shell and i3 changes)."
echo "=================================="
