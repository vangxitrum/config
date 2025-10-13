#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Tmux Plugin Reinstaller"
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

sudo apt-get install -y ruby ruby-dev tmux
sudo gem install tmuxinator

mkdir -p $HOME/.config/tmux
mkdir -p $HOME/.config/tmuxinator
cp -r ./tmux $HOME/.config
cp -r ./tmuxinator $HOME/.config

# Check if tmux is installed
if ! command -v tmux &>/dev/null; then
  print_error "Tmux is not installed. Please install tmux first."
  exit 1
fi

print_status "Tmux version: $(tmux -V)"
echo ""

# Check if .tmux.conf exists
TMUX_CONF="$HOME/.config/tmux/tmux.conf"
if [ ! -f "$TMUX_CONF" ]; then
  print_error "tmux.conf not found at $TMUX_CONF"
  exit 1
fi

print_success "Found tmux.conf"
echo ""

# Check TPM installation
echo "=================================="
echo "Checking TPM Installation"
echo "=================================="

TPM_DIR="$HOME/.config/tmux/plugins/tpm"

if [ ! -d "$TPM_DIR" ]; then
  print_warning "TPM not found. Installing..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  print_success "TPM installed at $TPM_DIR"
else
  print_success "TPM found at $TPM_DIR"
fi
echo ""

# Show completion message
echo "=================================="
print_success "Plugin Reinstall Complete!"
echo "=================================="
echo ""
print_status "Next steps:"
echo "  1. Start tmux: tmux"
echo "  2. If needed, press: prefix + I (to ensure all plugins are loaded)"
echo "  3. Reload config: tmux source-file ~/.tmux.conf"
echo "     Or inside tmux: prefix + r"
echo ""
print_status "Verify plugins:"
echo "  • List plugins: ls ~/.tmux/plugins/"
echo "  • Inside tmux: prefix + I (install/update)"
echo "  • Inside tmux: prefix + U (update all)"
echo ""
print_status "Troubleshooting:"
echo "  • If plugins don't work, restart tmux completely"
echo "  • Check plugin status inside tmux with: prefix + I"
echo "  • View TPM help: https://github.com/tmux-plugins/tpm"
echo ""
print_warning "Remember: Some plugins may require tmux restart to work properly"
