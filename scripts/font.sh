#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "FiraCode Nerd Font Installer"
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

# Detect OS
OS="$(uname -s)"
print_status "Detected OS: $OS"

# Set font directory based on OS
if [[ "$OS" == "Linux" ]]; then
  FONT_DIR="$HOME/.local/share/fonts"
elif [[ "$OS" == "Darwin" ]]; then
  FONT_DIR="$HOME/Library/Fonts"
else
  print_error "Unsupported OS: $OS"
  exit 1
fi

print_status "Font directory: $FONT_DIR"

# Create font directory if it doesn't exist
mkdir -p "$FONT_DIR"

# Download FiraCode Nerd Font
FONT_NAME="FiraCode"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip"
TEMP_DIR=$(mktemp -d)

print_status "Downloading $FONT_NAME Nerd Font..."
cd "$TEMP_DIR"

if command -v wget &>/dev/null; then
  wget -q --show-progress "$FONT_URL" -O "$FONT_NAME.zip"
elif command -v curl &>/dev/null; then
  curl -L -o "$FONT_NAME.zip" "$FONT_URL"
else
  print_error "Neither wget nor curl found. Please install one of them."
  exit 1
fi

print_status "Extracting fonts..."
unzip -q "$FONT_NAME.zip" -d "$FONT_NAME"

print_status "Installing fonts to $FONT_DIR..."
find "$FONT_NAME" -name "*.ttf" -o -name "*.otf" | while read -r font; do
  cp "$font" "$FONT_DIR/"
done

# Update font cache
print_status "Updating font cache..."
if [[ "$OS" == "Linux" ]]; then
  if command -v fc-cache &>/dev/null; then
    fc-cache -fv "$FONT_DIR" >/dev/null 2>&1
  else
    print_status "fc-cache not found. You may need to install fontconfig package."
  fi
elif [[ "$OS" == "Darwin" ]]; then
  # macOS automatically updates font cache
  print_status "macOS will automatically update font cache."
fi

# Cleanup
print_status "Cleaning up..."
cd ~
rm -rf "$TEMP_DIR"

print_success "FiraCode Nerd Font installed successfully!"
echo ""
print_status "To use the font:"
echo "  - Terminal: Set your terminal font to 'FiraCode Nerd Font'"
echo "  - VS Code: Add to settings.json:"
echo '    "editor.fontFamily": "FiraCode Nerd Font"'
echo '    "terminal.integrated.fontFamily": "FiraCode Nerd Font"'
echo ""
print_status "You may need to restart your applications to see the new font."
