#!/bin/bash

set -e # Exit on error
sudo apt-get update && apt-get install -y \
  curl \
  wget \
  git \
  make \
  sudo \
  ca-certificates \
  software-properties-common \
  unzip \
  flameshot \
  bsdmainutils

cd $HOME

mkdir -p setup

cd $HOME/setup

git clone https://github.com/vangxitrum/config.git

cd config

sudo chmod +x ./scripts/*.sh

sudo ./scripts/zsh.sh

sudo ./scripts/language.sh

sudo ./scripts/i3.sh

sudo ./scripts/tmux.sh

sudo ./scripts/nvim.sh

sudo ./scripts/font.sh

sudo add-apt-repository ppa:ubuntu-vn/ppa
sudo apt-get install -y ibus-unikey

echo "DONE"
