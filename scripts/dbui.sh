#!/bin/bash
# dbui.sh - vim-dadbod-ui in its own kitty window, on i3 workspace 4:db.
#
# The window gets its own X class (com.chum.dbui) so i3 can tell it apart from
# the main terminal (kitty, workspace 1) and assign it to
# workspace 4 (config/i3/config). nvim runs in tmux because `pgpass unlock`
# only works inside tmux, but on its own server (`tmux -L dbui`, status bar
# off) so it never shows up in, or shares state with, your main tmux.
# pgpass keeps passwords until the last unlocked tmux server exits.
# Running it again focuses the open window instead of starting another.
#
# Usage: dbui.sh [--background]
#   (i3: $mod+Shift+d, shell: `dbui`; i3 autostart uses --background so login
#   stays on workspace 1 while the window opens on 4:db)
#   Over SSH (or with no display) it opens the same session in the current
#   terminal instead: the one already running on the desktop, or a new one.
set -euo pipefail

CLASS="com.chum.dbui"
SOCKET="dbui"
SESSION="db"
WORKSPACE="4:db" # must match $ws4 in config/i3/config
PGPASS="$HOME/work/config/scripts/pgpass.sh"
# Working directory: dadbod-ui's saved queries, kept in this repo
# (g:db_ui_save_location in config/nvim/lua/chum/lazy/dadbod.lua), so pickers,
# :e and toggleterm start there.
ROOT="$HOME/work/config/config/db_ui"

BACKGROUND=false
[ "${1:-}" = "--background" ] && BACKGROUND=true

mkdir -p "$ROOT"

# zsh -i loads ~/.zshrc for PATH and PGPASSFILE (i3's environment has neither).
session=(tmux -L "$SOCKET" new-session -A -s "$SESSION" -c "$ROOT"
	"zsh -ic '$PGPASS unlock; exec nvim +DBUI'" \; set-option status off)

# SSH or no X: no kitty or i3 to drive, so attach right here. TMUX is
# cleared so it also works from inside your main tmux (a nested client; press
# the prefix twice to reach the inner one). Detach with prefix d: the session
# keeps running, also on the desktop.
# Inside tmux, a shell's own SSH_CONNECTION/DISPLAY date from when it started;
# tmux's session environment follows the client that attached last.
over_ssh() {
	if [ -n "${TMUX:-}" ]; then
		tmux show-environment SSH_CONNECTION 2>/dev/null | grep -q '^SSH_CONNECTION='
		return
	fi
	[ -n "${SSH_CONNECTION:-}" ] || [ -z "${DISPLAY:-}" ]
}
if [ -z "${DISPLAY:-}" ] || over_ssh; then
	exec env -u TMUX "${session[@]}"
fi

if i3-msg -t get_tree | grep -q "\"class\":\"$CLASS\""; then
	$BACKGROUND || i3-msg -q "[class=\"^com\\.chum\\.dbui\$\"] focus"
	exit 0
fi

# i3 assigns the window to $WORKSPACE; follow it there unless autostarting.
$BACKGROUND || i3-msg -q "workspace $WORKSPACE"

exec kitty --class="$CLASS" --title="DB" --directory="$ROOT" "${session[@]}"
