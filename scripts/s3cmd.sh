#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "s3cmd Installation"
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

# Install s3cmd
if command -v s3cmd &>/dev/null; then
    print_status "s3cmd already installed: $(s3cmd --version)"
else
    print_status "Installing s3cmd..."
    sudo apt-get update
    sudo apt-get install -y s3cmd
    print_success "s3cmd installed successfully!"
fi

# Configuration Hint
echo ""
print_status "To configure s3cmd, run:"
echo "  s3cmd --configure"
echo ""

print_success "s3cmd setup complete!"
