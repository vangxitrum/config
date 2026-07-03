#!/bin/bash

set -e # Exit on error

echo "=================================="
echo "Tmux Installer"
echo "=================================="
echo ""

sudo apt-get install -y nitrogen i3 polybar

echo "=================================="
echo "I3 Installer"
echo "=================================="
echo ""

sudo apt-get install -y i3 polybar

# i3 & polybar configs are symlinked by install.sh.
