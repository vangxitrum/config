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
echo "Installing NVM (Node.js)"
echo "=================================="
if [ -d "$HOME/.nvm" ]; then
    print_status "NVM already installed, skipping..."
else
    print_status "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    print_success "NVM installed successfully!"
    print_status "Usage: nvm install node (latest), nvm install 18, nvm use 18"
fi
echo ""

# Shell Configuration
echo "=================================="
echo "Shell Configuration for Node.js"
echo "=================================="
print_status "Add the following to your ~/.bashrc or ~/.zshrc:"
echo ""
echo "# NVM"
echo 'export NVM_DIR="$HOME/.nvm"'
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
echo ""
print_status "Then run: source ~/.bashrc (or source ~/.zshrc)"
echo ""

echo '' >>~/.profile
echo '# NVM' >>~/.profile
echo 'export NVM_DIR="$HOME/.nvm"' >>~/.profile
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >>~/.profile
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >>~/.profile

print_success "Node.js installation complete!"
