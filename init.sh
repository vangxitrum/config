#!/bin/bash

set -e # Exit on error
sudo apt-get update && apt-get install -y \
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
  bsdmainutils

cd $HOME

mkdir -p setup

cd $HOME/setup

git clone https://github.com/vangxitrum/config.git

cd config

sudo chmod +x ./scripts/*.sh

# Languages
sudo ./scripts/go.sh
sudo ./scripts/node.sh
sudo ./scripts/python.sh
sudo ./scripts/luarocks.sh

# Environment and Tools
sudo ./scripts/zsh.sh
sudo ./scripts/docker.sh
sudo ./scripts/i3.sh
sudo ./scripts/tmux.sh
sudo ./scripts/nvim.sh
sudo ./scripts/ghostty.sh
sudo ./scripts/font.sh

# Install Fcitx5 for Telex (Vietnamese)
sudo apt-get install -y fcitx5 fcitx5-unikey im-config

# Set Fcitx5 as default input method
im-config -n fcitx5

# Add Fcitx5 environment variables to .profile
echo '
# Fcitx5
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx' >>~/.profile

echo "DONE"
