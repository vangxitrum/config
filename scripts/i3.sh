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

cp -r ./i3 $HOME/.config
cp -r ./polybar $HOME/.config
