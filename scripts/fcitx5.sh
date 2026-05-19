#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Fcitx5 Configuration"
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

# Create config directory
mkdir -p "$HOME/.config/fcitx5"

# Configure Fcitx5 global options
# This sets Ctrl+Shift (both Left and Right) as a toggle/enumerate forward key
print_status "Setting Ctrl+Shift as input method toggle..."
cat >"$HOME/.config/fcitx5/config" <<EOF
[Hotkey]
# Enumerate Forward Key
EnumerateForwardKeys=Control+Shift_L,Control+Shift_R
# Enumerate Backward Key
EnumerateBackwardKeys=
# Skip first input method when enumerating
EnumerateSkipFirst=False

[Hotkey/TriggerKeys]
0=Control+space
1=Zenkaku_Hankaku
2=Hangul

[Hotkey/AltTriggerKeys]
0=Shift_L

[Behavior]
# Active By Default
ActiveByDefault=False
# Share Input State
ShareInputState=No
# Show Input Method Information when focus on an input box
ShowInputMethodInformation=True
# Show Input Method Information when switching input method
ShowInputMethodInformationWhenSwitching=True
# Type of the password
PasswordHint=True
# Use first input method for password
PasswordUseFirstInputMethod=True
EOF

# Configure Unikey (Vietnamese)
mkdir -p "$HOME/.config/fcitx5/conf"
cat >"$HOME/.config/fcitx5/conf/unikey.conf" <<EOF
[Editor]
# Default Input Method State
DefaultState=Vietnamese
# Telex
Telex=True
# VNI
VNI=False
# STelex
STelex=False
# STelex2
STelex2=False
EOF

# Ensure fcitx5 starts with the correct input methods
# 1. Keyboard - US
# 2. Unikey (Vietnamese)
cat >"$HOME/.config/fcitx5/profile" <<EOF
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=unikey

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=unikey
Layout=

[GroupOrder]
0=Default
EOF

print_success "Fcitx5 configured with Ctrl+Shift toggle!"
