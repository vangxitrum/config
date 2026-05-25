#!/usr/bin/env bash
state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-jump"
origin_file="$state_dir/origin"

if [ -s "$origin_file" ]; then
	origin=$(cat "$origin_file")
	tmux switch-client -t "$origin"
	rm -f "$origin_file"
else
	tmux last-window
fi
