#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "CLI Tools (btop, keychain, lazydocker)"
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

# Older installs put lazydocker in ~/go/bin; this shell has not sourced ~/.profile.
export PATH="$HOME/.local/bin:$PATH:$HOME/go/bin"

# btop: resource monitor. keychain: one shared ssh-agent per boot (see home/.zshrc).
print_status "Installing btop and keychain..."
sudo apt-get update
sudo apt-get install -y btop keychain

# lazydocker from the upstream release binary: `go install` does not use the
# repo's vendored deps and fails to compile against current docker modules.
if command -v lazydocker &>/dev/null; then
    print_status "lazydocker already installed"
else
    print_status "Installing lazydocker..."
    case "$(uname -m)" in
    x86_64) LD_ARCH="x86_64" ;;
    aarch64) LD_ARCH="arm64" ;;
    *)
        print_error "Unsupported architecture: $(uname -m)"
        exit 1
        ;;
    esac
    LD_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazydocker/releases/latest |
        sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p')
    TMP_DIR=$(mktemp -d)
    curl -fsSL -o "$TMP_DIR/lazydocker.tar.gz" \
        "https://github.com/jesseduffield/lazydocker/releases/download/v${LD_VERSION}/lazydocker_${LD_VERSION}_Linux_${LD_ARCH}.tar.gz"
    tar -xzf "$TMP_DIR/lazydocker.tar.gz" -C "$TMP_DIR" lazydocker
    install -Dm 755 "$TMP_DIR/lazydocker" -t "$HOME/.local/bin"
    rm -rf "$TMP_DIR"
    print_success "lazydocker $LD_VERSION installed successfully!"
fi

echo ""
print_success "CLI tools setup complete!"
