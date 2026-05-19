#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Luarocks Installation"
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

# Check if running on Linux
OS="$(uname -s)"
if [[ "$OS" != "Linux" ]]; then
    print_error "This script is primarily designed for Linux (Ubuntu/Debian). Detected OS: $OS"
fi

# Install dependencies
echo "=================================="
echo "Installing dependencies"
echo "=================================="
print_status "Installing Lua 5.1 and build essentials..."
sudo apt-get update
sudo apt-get install -y lua5.1 liblua5.1-0-dev build-essential unzip wget libreadline-dev

# Luarocks Version
VERSION="3.11.1"

# Check if already installed
if command -v luarocks &>/dev/null; then
    CURRENT_VERSION=$(luarocks --version | head -n1 | awk '{print $2}')
    if [ "$CURRENT_VERSION" == "$VERSION" ]; then
        print_status "Luarocks $VERSION already installed, skipping..."
        exit 0
    fi
    print_status "Found Luarocks $CURRENT_VERSION, updating to $VERSION..."
fi

# Download and install Luarocks
echo "=================================="
echo "Downloading and Building Luarocks $VERSION"
echo "=================================="
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

print_status "Downloading Luarocks $VERSION..."
wget -q https://luarocks.org/releases/luarocks-$VERSION.tar.gz
tar zxpf luarocks-$VERSION.tar.gz
cd luarocks-$VERSION

print_status "Configuring Luarocks..."
./configure --with-lua-include=/usr/include/lua5.1

print_status "Building Luarocks..."
make

print_status "Installing Luarocks..."
sudo make install

# Cleanup
cd ~
rm -rf "$TEMP_DIR"

print_success "Luarocks $VERSION installed successfully!"

# Shell Configuration
echo ""
echo "=================================="
echo "Shell Configuration"
echo "=================================="
if ! grep -q "LUAROCKS" "$HOME/.profile"; then
    print_status "Adding Luarocks PATH to ~/.profile..."
    echo '' >>~/.profile
    echo '# Luarocks' >>~/.profile
    echo 'export PATH="$PATH:$HOME/.luarocks/bin"' >>~/.profile
    print_success "Updated ~/.profile"
else
    print_status "Luarocks configuration already exists in ~/.profile"
fi

# Verify
echo ""
echo "=================================="
echo "Verifying Installation"
echo "=================================="
if command -v luarocks &>/dev/null; then
    print_success "Luarocks is installed: $(luarocks --version | head -n1)"
else
    print_error "Luarocks installation verification failed"
    exit 1
fi

echo ""
print_success "Luarocks installation complete!"
