#!/bin/bash

set -e # Exit on error
sudo apt-get update && sudo apt-get install -y \
  curl \
  wget \
  git \
  make \
  sudo \
  zsh \
  ca-certificates \
  software-properties-common \
  unzip \
  xclip \
  flameshot \
  bsdmainutils \
  fontconfig

# Only clone if we are not already in a config directory
if [ ! -f "./init.sh" ]; then
  cd $HOME
  mkdir -p setup
  cd $HOME/setup
  git clone https://github.com/vangxitrum/config.git
  cd config
fi

chmod +x ./scripts/*.sh

# terninal
./scripts/zsh.sh

# Languages
./scripts/node.sh
./scripts/python.sh
./scripts/luarocks.sh
./scripts/go.sh

# Environment and Tools
./scripts/docker.sh
./scripts/i3.sh
./scripts/tmux.sh
./scripts/nvim.sh
./scripts/ghostty.sh
./scripts/font.sh
./scripts/dunst.sh

# Install Fcitx5 for Telex (Vietnamese)
sudo apt-get install -y fcitx5 fcitx5-unikey im-config

# Set Fcitx5 as default input method
im-config -n fcitx5

# Configure Fcitx5 (Shortcuts, Telex, etc.)
./scripts/fcitx5.sh

# Add Fcitx5 environment variables to .profile
echo '
# Fcitx5
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx' >>~/.profile

echo "DONE"
