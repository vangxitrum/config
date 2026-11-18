#!/bin/bash
# init.sh - install tools, then link dotfiles.
#
# Usage: ./init.sh [--headless]
#   --headless  skip desktop-only parts (i3, kitty, dunst, fonts, fcitx5,
#               flameshot, xclip) for servers and VPSes with no display.

set -e # Exit on error

HEADLESS=false
for arg in "$@"; do
  case "$arg" in
    --headless) HEADLESS=true ;;
    -h|--help)
      sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown option: $arg (try --help)" >&2
      exit 1
      ;;
  esac
done

APT_PACKAGES=(
  ripgrep
  curl
  wget
  git
  make
  sudo
  zsh
  ca-certificates
  software-properties-common
  unzip
  bsdmainutils
  fontconfig
)
$HEADLESS || APT_PACKAGES+=(xclip)

sudo apt-get update && sudo apt-get install -y "${APT_PACKAGES[@]}"

# Only clone if we are not already in a config directory
if [ ! -f "./init.sh" ]; then
  mkdir -p "$HOME/work"
  cd "$HOME/work"
  git clone https://github.com/vangxitrum/config.git
  cd config
fi

chmod +x ./install.sh ./scripts/*.sh

# terninal
./scripts/zsh.sh

# Languages
./scripts/node.sh
./scripts/python.sh
./scripts/luarocks.sh
./scripts/go.sh

# Environment and Tools
./scripts/docker.sh
./scripts/tmux.sh
./scripts/nvim.sh
./scripts/s3cmd.sh
./scripts/git.sh
./scripts/tools.sh
./scripts/postgres-client.sh
./scripts/agents.sh

if ! $HEADLESS; then
  # i3, its tools and Fcitx5 install under ~/.local (scripts/i3.sh); no sudo.
  ./scripts/i3.sh
  ./scripts/kitty.sh
  ./scripts/font.sh
  ./scripts/dunst.sh
  # No session-wide ssh-agent (GNOME Keyring/gpg/systemd); `sshkey` on demand.
  ./scripts/sshkey.sh setup

  # Fcitx5 for Telex (Vietnamese): writes ~/.config/fcitx5. The input-method
  # variables are set by start-i3's session script.
  ./scripts/fcitx5.sh
fi

# Symlink all configs and home dotfiles into place.
# On a headless machine the desktop configs (i3, polybar, ...) are linked too;
# they are inert without a display and keep every machine's layout identical.
./install.sh

echo "DONE"
