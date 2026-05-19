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
./scripts/go.sh
./scripts/node.sh
./scripts/python.sh
./scripts/luarocks.sh

# Environment and Tools
./scripts/zsh.sh
./scripts/docker.sh
./scripts/i3.sh
./scripts/tmux.sh
./scripts/nvim.sh
./scripts/ghostty.sh
./scripts/font.sh

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
