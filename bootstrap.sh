#!/bin/bash

# This script is a "one-liner" bootstrap for a fresh Ubuntu installation.
# It installs basic dependencies, clones the repository, and runs the initialization.
# Arguments are passed to init.sh, e.g. `bash -s -- --headless` for a server.

set -e

echo "=================================="
echo "Ubuntu Bootstrap & Config Setup"
echo "=================================="

# Update and install git/curl
sudo apt-get update
sudo apt-get install -y git curl

# Define target directory (must match the absolute paths in tmux/i3/claude configs)
TARGET_DIR="$HOME/work/config"
mkdir -p "$HOME/work"

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
./init.sh "$@"

echo ""
echo "=================================="
echo "Bootstrap Complete!"
echo "Please restart your computer to apply all changes (especially shell and i3 changes)."
echo "=================================="
