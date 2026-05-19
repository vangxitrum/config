#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Docker Installation"
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

# Check if docker is already installed
if command -v docker &>/dev/null; then
    print_status "Docker already installed, skipping installation..."
else
    print_status "Installing Docker..."

    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    print_success "Docker installed successfully!"
fi

# Add user to docker group
echo "=================================="
echo "Configuring Docker Permissions"
echo "=================================="

# Get the current username reliably
CURRENT_USER=$(id -u -n)

# Ensure the docker group exists
if ! getent group docker >/dev/null; then
    print_status "Creating docker group..."
    sudo groupadd docker || true
fi

if [ "$CURRENT_USER" == "root" ]; then
    print_status "Running as root, skipping user group assignment."
else
    print_status "Adding user $CURRENT_USER to docker group..."
    sudo usermod -aG docker "$CURRENT_USER"
    print_success "User $CURRENT_USER added to docker group."
    print_status "Note: You may need to log out and back in (or run 'newgrp docker') for this to take effect."
fi

print_success "Docker setup complete!"
