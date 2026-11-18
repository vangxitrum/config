#!/bin/bash
# Install kitty for this user only (~/.local/kitty.app), using kitty's official
# installer. Skips machines that already have kitty. The config is linked by
# install.sh (config/kitty -> ~/.config/kitty).
set -euo pipefail

if (( EUID == 0 )); then
  echo "Run this as the user who will use kitty." >&2
  exit 1
fi

if command -v kitty >/dev/null; then
  echo "kitty is already installed: $(command -v kitty)"
  exit 0
fi

curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
ln -sfn "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
ln -sfn "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
sed "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|; s|Exec=kitty|Exec=$HOME/.local/bin/kitty|" \
  "$HOME/.local/kitty.app/share/applications/kitty.desktop" > "$HOME/.local/share/applications/kitty.desktop"
echo "Installed kitty under $HOME/.local/kitty.app."
