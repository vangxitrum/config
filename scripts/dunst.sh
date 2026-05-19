#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Dunst Installation"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Install Dunst
print_status "Installing Dunst and libnotify..."
sudo apt-get update
sudo apt-get install -y dunst libnotify-bin

# Configuration
echo "=================================="
echo "Configuring Dunst"
echo "=================================="
print_status "Copying Dunst configuration..."
mkdir -p "$HOME/.config/dunst"
cp -r ./dunst/dunstrc "$HOME/.config/dunst/dunstrc"

print_status "Copying Dunst notification handler..."
mkdir -p "$HOME/.config/scripts"
cp ./scripts/dunst_handler.sh "$HOME/.config/scripts/dunst_handler.sh"
chmod +x "$HOME/.config/scripts/dunst_handler.sh"

print_success "Dunst installation and configuration complete!"
