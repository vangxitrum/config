#!/bin/bash
# update.sh — bring this machine up to date with the repo.
#
# Pulls the latest config, relinks (install.sh is idempotent, so new config
# dirs get linked and existing links are left alone), restores nvim plugins to
# lazy-lock.json, and reloads tmux/i3 if they are running.
#
# Refuses to run when the repo has uncommitted changes: since configs are
# symlinked, those are live edits made on this machine that must be committed
# (or discarded) first, otherwise the pull could silently mix the two.

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${BLUE}[UPDT]${NC} $1"; }
ok()    { echo -e "${GREEN}[ OK ]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; }

if [ -n "$(git status --porcelain)" ]; then
  fail "uncommitted changes in $DOTFILES_DIR — commit or stash them first:"
  git status --short
  exit 1
fi

info "pulling latest config"
git pull --rebase

info "linking"
./install.sh

if command -v nvim >/dev/null; then
  info "restoring nvim plugins to lazy-lock.json"
  nvim --headless "+Lazy! restore" +qa
fi

if command -v tmux >/dev/null && tmux info >/dev/null 2>&1; then
  tmux source-file "$HOME/.config/tmux/tmux.conf" && ok "tmux reloaded"
fi

if command -v i3-msg >/dev/null && pgrep -x i3 >/dev/null; then
  i3-msg -q reload && ok "i3 reloaded"
fi

# Reset the drift-check stamp (see home/.zshrc) so the next shell re-fetches.
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/config-drift-fetch"

echo ""
ok "Up to date: $(git log -1 --format='%h %s')"
