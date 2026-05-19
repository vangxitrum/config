#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Ghostty Terminal Installation"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running on Ubuntu/Debian
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" && "$ID" != "linuxmint" && "$ID" != "pop" ]]; then
        print_warning "This script is optimized for Ubuntu/Debian. It may work on your system ($ID) but is not tested."
    fi
else
    print_warning "Cannot detect OS. Proceeding anyway..."
fi

# Check for existing Ghostty
if command -v ghostty &>/dev/null; then
    CURRENT_VERSION=$(ghostty --version 2>/dev/null | head -n 1 || echo "unknown")
    print_status "Found existing Ghostty: $CURRENT_VERSION. Skipping installation."
else
    # Install via PPA (Recommended for Ubuntu)
    echo "=================================="
    echo "Installing Ghostty via PPA"
    echo "=================================="

    print_status "Adding PPA ppa:mkasberg/ghostty-ubuntu..."
    sudo add-apt-repository -y ppa:mkasberg/ghostty-ubuntu

    print_status "Updating package lists..."
    sudo apt-get update

    print_status "Installing Ghostty..."
    sudo apt-get install -y ghostty
fi

# Configuration
echo "=================================="
echo "Configuring Ghostty"
echo "=================================="
print_status "Copying Ghostty configuration..."
mkdir -p "$HOME/.config/ghostty"
cp -r ./ghostty/config "$HOME/.config/ghostty/config"

# Verify installation
echo ""
echo "=================================="
echo "Verifying Installation"
echo "=================================="
if command -v ghostty &>/dev/null; then
    INSTALLED_VERSION=$(ghostty --version 2>/dev/null || echo "installed")
    print_success "Ghostty is installed successfully!"
    print_status "Installation path: $(which ghostty)"
else
    print_error "Ghostty installation verification failed"
    exit 1
fi

echo ""
echo "=================================="
print_success "Installation Complete!"
echo "=================================="
echo ""
print_status "You can now launch Ghostty from your application menu or by running 'ghostty' in your terminal."
