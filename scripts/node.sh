#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Node.js Installation (NVM)"
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

# Install NVM (Node Version Manager)
echo "=================================="
echo "Installing/Updating NVM (Node.js)"
echo "=================================="
NVM_VERSION="v0.40.4"
print_status "Installing/Updating NVM $NVM_VERSION..."
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

print_status "Installing latest Node.js..."
nvm install node
nvm use node
nvm alias default node

print_success "NVM and Node.js (latest) installed/updated successfully!"
print_status "Installed Node version: $(node -v)"
print_status "Usage: nvm install 22, nvm use 22"
echo ""

# Shell Configuration
echo "=================================="
echo "Shell Configuration for Node.js"
echo "=================================="
if ! grep -q "NVM_DIR" "$HOME/.profile"; then
    print_status "Adding NVM configuration to ~/.profile..."
    echo '' >>~/.profile
    echo '# NVM' >>~/.profile
    echo 'export NVM_DIR="$HOME/.nvm"' >>~/.profile
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >>~/.profile
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >>~/.profile
    print_success "Updated ~/.profile"
else
    print_status "NVM configuration already exists in ~/.profile"
fi

print_status "To use NVM in your current shell, run:"
echo 'export NVM_DIR="$HOME/.nvm"'
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
echo ""

print_success "Node.js installation complete!"
