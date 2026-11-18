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

DOCKER_PACKAGES=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
if [[ "${1:-}" == "--cli-only" ]]; then
    DOCKER_PACKAGES=(docker-ce-cli docker-buildx-plugin docker-compose-plugin)
fi

# Check if docker is already installed
if command -v docker &>/dev/null; then
    print_status "Docker already installed, skipping installation..."
else
    print_status "Installing Docker..."

    # Add Docker's official GPG key:
    print_status "Updating package lists..."
    sudo apt-get update || (sleep 5 && sudo apt-get update)
    
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    
    print_status "Downloading Docker GPG key (with retries)..."
    # Using --retry to handle transient DNS/network issues
    if ! curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
        print_error "Failed to download Docker GPG key. This is likely a DNS or network issue."
        print_status "Tip: If you are in a Docker build, try adding --network=host or checking your DNS settings."
        exit 1
    fi
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt-get update
    sudo apt-get install -y "${DOCKER_PACKAGES[@]}"

    print_success "Docker installed successfully!"
fi

if [[ "${1:-}" == "--cli-only" ]]; then
    exit 0
fi

# Rootless Docker (no sudo): no docker group to join. Keep client IPs on
# published ports, let containers reach the
# host's 127.0.0.1 and make `host-gateway` (host.docker.internal in
# compose.coding.yaml and scripts/pg-docker.sh) point there. By default
# host-gateway is the bridge gateway inside rootlesskit's network namespace,
# where neither published ports nor host SSH tunnels are reachable;
# 10.0.2.2 is slirp4netns' address for the host's loopback.
if [[ "$(docker context show 2>/dev/null)" == "rootless" ]]; then
    echo "=================================="
    echo "Configuring rootless Docker networking"
    echo "=================================="
    dropin="$HOME/.config/systemd/user/docker.service.d/host-loopback.conf"
    daemon_json="$HOME/.config/docker/daemon.json"
    changed=false

    # slirp4netns port driver: published ports see the real client IP (the
    # builtin driver makes every client 172.17.0.1), which the coding
    # container's ufw needs to allow only one address. A bit slower.
    want_dropin=$'[Service]\nEnvironment=DOCKERD_ROOTLESS_ROOTLESSKIT_DISABLE_HOST_LOOPBACK=false\nEnvironment=DOCKERD_ROOTLESS_ROOTLESSKIT_PORT_DRIVER=slirp4netns\n'
    if [[ "$(cat "$dropin" 2>/dev/null)"$'\n' != "$want_dropin" ]]; then
        mkdir -p "$(dirname "$dropin")"
        printf '%s' "$want_dropin" >"$dropin"
        changed=true
    fi

    if ! grep -q '"host-gateway-ips"' "$daemon_json" 2>/dev/null; then
        if [[ -s "$daemon_json" ]]; then
            print_error "$daemon_json exists; add \"host-gateway-ips\": [\"10.0.2.2\"] to it by hand."
        else
            mkdir -p "$(dirname "$daemon_json")"
            printf '{\n  "host-gateway-ips": ["10.0.2.2"]\n}\n' >"$daemon_json"
            changed=true
        fi
    fi

    if $changed; then
        print_status "Restarting rootless dockerd (running containers restart only if they have a restart policy)..."
        systemctl --user daemon-reload
        systemctl --user restart docker
    fi
    print_success "host.docker.internal -> host loopback (10.0.2.2) for rootless Docker."
    exit 0
fi

# Add user to docker group
echo "=================================="
echo "Configuring Docker Permissions"
echo "=================================="

# Get the current username reliably
CURRENT_USER=$(whoami || echo $USER)

# Ensure the docker group exists
if ! getent group docker >/dev/null; then
    print_status "Creating docker group..."
    sudo groupadd docker || true
fi

if [ "$CURRENT_USER" == "root" ] || [ -z "$CURRENT_USER" ]; then
    print_status "Skipping user group assignment (User: ${CURRENT_USER:-empty})."
else
    print_status "Adding user $CURRENT_USER to docker group..."
    sudo usermod -aG docker "$CURRENT_USER"
    print_success "User $CURRENT_USER added to docker group."
    print_status "Note: You may need to log out and back in (or run 'newgrp docker') for this to take effect."
fi

print_success "Docker setup complete!"
