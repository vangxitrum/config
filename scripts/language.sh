#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Version Managers Installation"
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
    sudo apt clean
    rm -rf /var/lib/apt/lists/*

    print_status "Installing GVM..."
    bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)

    print_success "GVM installed successfully!"
    print_status "Usage: gvm install go1.21.0, gvm use go1.21.0 --default"
fi
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
    bash "$MINICONDA_INSTALLER" -b -p "$HOME/miniconda3"
    rm "$MINICONDA_INSTALLER"

    # Initialize conda
    "$HOME/miniconda3/bin/conda" init bash

    print_success "Miniconda installed successfully!"
    print_status "Usage: conda create -n myenv python=3.11, conda activate myenv"
fi
echo ""

# Print shell configuration instructions
echo "=================================="
echo "Shell Configuration"
echo "=================================="
print_status "Add the following to your ~/.bashrc or ~/.zshrc:"
echo ""
echo "# NVM"
echo 'export NVM_DIR="$HOME/.nvm"'
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
echo ""
echo "# pyenv"
echo 'export PYENV_ROOT="$HOME/.pyenv"'
echo 'export PATH="$PYENV_ROOT/bin:$PATH"'
echo 'eval "$(pyenv init -)"'
echo ""
echo "# GVM"
echo '[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"'
echo ""
print_status "Then run: source ~/.bashrc (or source ~/.zshrc)"
echo ""

echo '' >>~/.profile &&
    echo '# NVM' >>~/.profile &&
    echo 'export NVM_DIR="$HOME/.nvm"' >>~/.profile &&
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >>~/.profile &&
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >>~/.profile &&
    echo '' >>~/.profile &&
    echo '# GVM' >>~/.profile &&
    echo '[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"' >>~/.profile

print_success "Installation complete!"
print_status "Restart your terminal or source your shell config to use the version managers."
