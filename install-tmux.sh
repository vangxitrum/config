#!/usr/bin/env bash
set -euo pipefail

if (( EUID == 0 )); then
  echo "Run this script as your regular user." >&2
  exit 1
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target="$HOME/.tmux.conf"
helpers="$HOME/.local/share/config-tmux/scripts"

install -d -- "$helpers"
for helper in clip tmux-weather tmux-jump-last-notify tmux-jump-back agent-notify-mode agent-notify-lib agent-state; do
  install -m 755 -- "$repo_dir/scripts/$helper.sh" "$helpers/$helper.sh"
done

config="$(mktemp "$HOME/.tmux.conf.new.XXXXXXXX")"
trap 'rm -f -- "$config"' EXIT

# Keep the repo's desktop config usable from its existing installation paths.
sed \
  -e 's|source-file ~/.config/tmux/tmux.conf|source-file ~/.tmux.conf|' \
  -e 's|~/work/config/scripts/|~/.local/share/config-tmux/scripts/|g' \
  -e "s|^run '~/.config/tmux/plugins/tpm/tpm'|if-shell 'test -x ~/.config/tmux/plugins/tpm/tpm' \"run-shell '~/.config/tmux/plugins/tpm/tpm'\"|" \
  "$repo_dir/config/tmux/tmux.conf" > "$config"

if [[ -f "$target" && ! -L "$target" ]] && cmp -s -- "$config" "$target"; then
  printf 'Tmux config already up to date at %s\n' "$target"
  exit 0
fi

if [[ -e "$target" || -L "$target" ]]; then
  backup="$(mktemp -d "$HOME/.tmux-backup.XXXXXXXX")"
  mv -- "$target" "$backup/.tmux.conf"
  printf 'Backed up previous config to %s\n' "$backup/.tmux.conf"
fi
mv -T -- "$config" "$target"
printf 'Installed tmux config at %s\n' "$target"
