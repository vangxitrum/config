#!/usr/bin/env bash
# Claude Code Stop/Notification hook → persistent notify-send carrying a tmux
# jump target in the `category` field. State (target + notification id) is
# tracked in $XDG_CACHE_HOME/tmux-jump/active so tmux-jump-last-notify.sh can
# both verify the notification is still active and close it on jump.
#
# Usage: claude-notify.sh <event>        event = stop | notification
# Notification event reads the hook JSON payload from stdin.

set -u

event="${1:-stop}"

case "$event" in
	stop)
		urgency="low"
		body="Turn complete"
		;;
	notification)
		body=$(jq -r '.message // "Input needed"')
		urgency="critical"
		;;
	*)
		urgency="low"
		body="$event"
		;;
esac

loc=""
tgt=""
if [ -n "${TMUX_PANE:-}" ]; then
	loc=$(tmux display-message -p -t "$TMUX_PANE" '#S:#W' 2>/dev/null || true)
	tgt=$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}' 2>/dev/null || true)
fi

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-jump"
state_file="$state_dir/active"

if [ -z "$tgt" ]; then
	notify-send -a "Claude Code" -u "$urgency" "Claude Code" "$body" 2>/dev/null || true
	exit 0
fi

mkdir -p "$state_dir"

prev_id=""
[ -f "$state_file" ] && prev_id=$(awk 'NR==2 {print; exit}' "$state_file" 2>/dev/null || true)

args=(-a "Claude Code" -u "$urgency" -c "tmux-target:$tgt" -t 0 -p)
[ -n "$prev_id" ] && args+=(-r "$prev_id")

new_id=$(notify-send "${args[@]}" "Claude Code [$loc]" "$body" 2>/dev/null || true)

if [ -n "$new_id" ]; then
	printf '%s\n%s\n' "$tgt" "$new_id" > "$state_file"
fi
