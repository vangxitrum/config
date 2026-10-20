#!/bin/bash
# install.sh — symlink dotfiles into place.
#
# Links config/<dir> -> ~/.config/<dir> and home/<dotfile> -> ~/<dotfile>.
# Idempotent: existing real files/dirs are backed up to *.bak.<timestamp>;
# existing correct symlinks are left untouched.
#
# fcitx5 is intentionally excluded: scripts/fcitx5.sh generates that config.

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$DOTFILES_DIR/config"
HOME_SRC="$DOTFILES_DIR/home"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${BLUE}[LINK]${NC} $1"; }
ok()    { echo -e "${GREEN}[ OK ]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

# link <source> <target>
link() {
  local src="$1" dst="$2"
  if [ ! -e "$src" ]; then
    warn "source missing, skip: $src"
    return
  fi
  # Already the correct symlink? nothing to do.
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    ok "$dst -> $src (already linked)"
    return
  fi
  # Back up anything real that is in the way.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local backup="$dst.bak.$(date +%Y%m%d_%H%M%S)"
    mv "$dst" "$backup"
    warn "backed up existing $dst -> $backup"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  info "$dst -> $src"
}

# ~/.config/<dir> for every dir under config/, except the exclude list.
EXCLUDE_CONFIG=("fcitx5")
mkdir -p "$HOME/.config"
for path in "$CONFIG_SRC"/*/; do
  name="$(basename "$path")"
  skip=false
  for e in "${EXCLUDE_CONFIG[@]}"; do
    [ "$name" = "$e" ] && skip=true
  done
  $skip && { warn "excluded (managed elsewhere): $name"; continue; }
  link "$CONFIG_SRC/$name" "$HOME/.config/$name"
done

# ~/<dotfile> for every entry under home/ (dotfiles included).
for path in "$HOME_SRC"/.[!.]* "$HOME_SRC"/*; do
  [ -e "$path" ] || continue
  name="$(basename "$path")"
  link "$HOME_SRC/$name" "$HOME/$name"
done

# Per-machine files: create <name>.local from <name>.local.example if missing.
# The .local copies are gitignored, so each machine keeps its own values.
while IFS= read -r example; do
  local_file="${example%.example}"
  if [ ! -e "$local_file" ]; then
    cp "$example" "$local_file"
    warn "created $local_file from template - edit it for this machine"
  fi
done < <(find "$CONFIG_SRC" "$HOME_SRC" -name '*.local.example' 2>/dev/null)

echo ""
ok "Dotfiles linked."
