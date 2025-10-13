#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Neovim 0.10+ Installation"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=================================="
echo "Copy config Neovim"
echo "=================================="
mkdir -p $HOME/.config/nvim
cp -r ./nvim $HOME/.config
echo ""

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

# Remove old Neovim if installed
echo "=================================="
echo "Checking for existing Neovim"
echo "=================================="
if command -v nvim &>/dev/null; then
  CURRENT_VERSION=$(nvim --version | head -n1)
  print_status "Found existing Neovim: $CURRENT_VERSION"
  read -p "Remove existing Neovim installation? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Removing old Neovim..."
    sudo apt-get remove -y neovim 2>/dev/null || true
    sudo rm -rf /usr/local/bin/nvim /usr/local/share/nvim 2>/dev/null || true
  fi
else
  print_status "No existing Neovim installation found"
fi
echo ""

# Install build dependencies
echo "=================================="
echo "Installing build dependencies"
echo "=================================="
print_status "Updating package lists..."
sudo apt-get update

print_status "Installing build dependencies..."
sudo apt-get install -y \
  ninja-build \
  gettext \
  cmake \
  unzip \
  curl \
  git \
  build-essential

print_success "Dependencies installed"
echo ""

# Clone Neovim repository
echo "=================================="
echo "Downloading Neovim source"
echo "=================================="
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

print_status "Cloning Neovim repository..."
git clone https://github.com/neovim/neovim.git
cd neovim

# Checkout stable version (v0.10.x)
print_status "Checking out stable release..."
git checkout stable

NVIM_VERSION=$(git describe --tags)
print_status "Building Neovim version: $NVIM_VERSION"
echo ""

# Build Neovim
echo "=================================="
echo "Building Neovim"
echo "=================================="
print_status "This may take several minutes..."
make CMAKE_BUILD_TYPE=RelWithDebInfo

print_success "Build completed"
echo ""

# Install Neovim
echo "=================================="
echo "Installing Neovim"
echo "=================================="
print_status "Installing to /usr/local..."
sudo make install

print_success "Neovim installed successfully!"
echo ""

# Cleanup
print_status "Cleaning up temporary files..."
cd ~
rm -rf "$TEMP_DIR"

# Verify installation
echo "=================================="
echo "Verifying Installation"
echo "=================================="
if command -v nvim &>/dev/null; then
  INSTALLED_VERSION=$(nvim --version | head -n1)
  print_success "Neovim is installed: $INSTALLED_VERSION"
  print_status "Installation path: $(which nvim)"
else
  print_error "Neovim installation verification failed"
  exit 1
fi

echo ""
echo "=================================="
print_success "Installation Complete!"
echo "=================================="
echo ""
print_status "Get started with Neovim:"
echo "  - Run: nvim"
echo "  - Tutorial: nvim +Tutor"
echo "  - Help: :help"
echo ""
print_status "Configuration:"
echo "  - Config directory: ~/.config/nvim/"
echo "  - Create init.lua: mkdir -p ~/.config/nvim && touch ~/.config/nvim/init.lua"
echo ""
print_status "Popular plugin managers:"
echo "  - lazy.nvim: https://github.com/folke/lazy.nvim"
echo "  - packer.nvim: https://github.com/wbthomason/packer.nvim"
echo ""
print_status "Suggested configurations:"
echo "  - LazyVim: https://www.lazyvim.org/"
echo "  - NvChad: https://nvchad.com/"
echo "  - AstroNvim: https://astronvim.com/"
