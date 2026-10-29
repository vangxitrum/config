#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Git Tools (gh, lazygit)"
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

# go.sh installs Go to /usr/local/go; this shell has not sourced ~/.profile yet.
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"

# GitHub CLI from the official apt repository (gets updates via apt).
if command -v gh &>/dev/null; then
    print_status "gh already installed: $(gh --version | head -1)"
else
    print_status "Installing gh..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
        sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
        sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y gh
    print_success "gh installed successfully!"
fi

# lazygit is not packaged on Ubuntu 24.04, so build it with Go.
if command -v lazygit &>/dev/null; then
    print_status "lazygit already installed"
elif command -v go &>/dev/null; then
    print_status "Installing lazygit..."
    go install github.com/jesseduffield/lazygit@latest
    print_success "lazygit installed successfully!"
else
    print_error "go not found, run ./scripts/go.sh first"
    exit 1
fi

# ~/.gitconfig is symlinked from home/.gitconfig by install.sh.

echo ""
print_success "Git tools setup complete!"
