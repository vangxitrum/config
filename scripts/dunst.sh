#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Dunst Installation"
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

# Install Dunst
print_status "Installing Dunst and libnotify..."
sudo apt-get update
sudo apt-get install -y dunst libnotify-bin

# Disable default Ubuntu notification daemon
print_status "Disabling default Ubuntu notification daemon..."
# Remove notify-osd if it exists, as it often conflicts with dunst
sudo apt-get purge -y notify-osd notification-daemon || true

# If there are any other services providing notifications, we should handle them
# Some systems have a generic service file that points to the default daemon
if [ -f /usr/share/dbus-1/services/org.freedesktop.Notifications.service ]; then
    sudo mv /usr/share/dbus-1/services/org.freedesktop.Notifications.service /usr/share/dbus-1/services/org.freedesktop.Notifications.service.bak || true
fi

# Configuration
echo "=================================="
echo "Configuring Dunst"
echo "=================================="
print_status "Copying Dunst configuration..."
mkdir -p "$HOME/.config/dunst"
cp -r ./dunst/dunstrc "$HOME/.config/dunst/dunstrc"

print_status "Copying Dunst notification handler..."
mkdir -p "$HOME/.config/scripts"
cp ./scripts/dunst_handler.sh "$HOME/.config/scripts/dunst_handler.sh"
chmod +x "$HOME/.config/scripts/dunst_handler.sh"

print_success "Dunst installation and configuration complete!"
