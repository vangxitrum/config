#!/usr/bin/env bash
# Return to the window+pane we were in before tmux-jump-last-notify.sh jumped.
# Falls back to last-window if no saved origin exists.

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-jump"
origin_file="$state_dir/origin"

if [ -s "$origin_file" ]; then
	origin_win=$(awk 'NR==1 {print; exit}' "$origin_file")
	origin_pane=$(awk 'NR==2 {print; exit}' "$origin_file")
	tmux switch-client -t "$origin_win"
	[ -n "$origin_pane" ] && tmux select-pane -t "$origin_pane" 2>/dev/null || true
	rm -f "$origin_file"
else
	tmux last-window
fi
