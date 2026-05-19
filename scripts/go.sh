#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Go Installation (GVM and Manual)"
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

# Check if running on Linux or macOS
OS="$(uname -s)"
print_status "Detected OS: $OS"
echo ""

# Install GVM (Go Version Manager)
echo "=================================="
echo "Installing GVM (Go)"
echo "=================================="
if [ -d "$HOME/.gvm" ]; then
    print_status "GVM already installed, skipping..."
else
    print_status "Installing GVM dependencies..."
    sudo apt-get update
    sudo apt-get -y install curl git mercurial make binutils bison gcc build-essential

    print_status "Installing GVM..."
    zsh < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)

    print_success "GVM installed successfully!"
    print_status "Usage: gvm install go1.21.0, gvm use go1.21.0 --default"
fi
echo ""

# Manual Go Installation
echo "=================================="
echo "Manual Go Installation"
echo "=================================="
GO_VERSION="1.23.2" # Change this to your desired version
INSTALL_DIR="/usr/local"

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
x86_64) GO_ARCH="amd64" ;;
aarch64) GO_ARCH="arm64" ;;
armv6l) GO_ARCH="armv6l" ;;
*)
    print_error "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

# Remove old Go installation if exists
sudo rm -rf "${INSTALL_DIR}/go"

# Download Go tarball
print_status "Downloading Go ${GO_VERSION} for ${GO_ARCH}..."
wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -O /tmp/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz

# Extract and install
print_status "Installing Go..."
sudo tar -C "${INSTALL_DIR}" -xzf /tmp/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz

# Clean up
rm /tmp/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz

# Shell Configuration
echo "=================================="
echo "Shell Configuration for Go"
echo "=================================="
print_status "Add the following to your ~/.bashrc or ~/.zshrc:"
echo ""
echo "# GVM"
echo '[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"'
echo ""
print_status "Then run: source ~/.bashrc (or source ~/.zshrc)"
echo ""

echo '' >>~/.profile
echo '# GVM' >>~/.profile
echo '[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"' >>~/.profile

print_success "Go installation complete!"
