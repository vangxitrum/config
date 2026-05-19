#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Python Installation (Miniconda)"
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

# Install Miniconda (Python)
echo "=================================="
echo "Installing Miniconda (Python)"
echo "=================================="
if [ -d "$HOME/miniconda3" ]; then
    print_status "Miniconda already installed, skipping..."
else
    print_status "Installing Miniconda..."

    MINICONDA_INSTALLER="Miniconda3-latest-Linux-x86_64.sh"
    cd /tmp
    curl -O "https://repo.anaconda.com/miniconda/$MINICONDA_INSTALLER"
    zsh "$MINICONDA_INSTALLER" -b -p "$HOME/miniconda3"
    rm "$MINICONDA_INSTALLER"

    # Initialize conda
    "$HOME/miniconda3/bin/conda" init bash

    print_success "Miniconda installed successfully!"
    print_status "Usage: conda create -n myenv python=3.11, conda activate myenv"
fi
echo ""

# Shell Configuration
echo "=================================="
echo "Shell Configuration for Python"
echo "=================================="
print_status "Add the following to your ~/.bashrc or ~/.zshrc (if using pyenv):"
echo ""
echo "# pyenv"
echo 'export PYENV_ROOT="$HOME/.pyenv"'
echo 'export PATH="$PYENV_ROOT/bin:$PATH"'
echo 'eval "$(pyenv init -)"'
echo ""
print_status "Conda initializes itself in ~/.bashrc automatically."
echo ""

print_success "Python installation complete!"
