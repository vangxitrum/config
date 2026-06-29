#!/usr/bin/env bash
# Shared agent Stop/Notification hook for Claude Code and Gemini CLI.
#
# One backend is active at a time (the toggle): tmux | dunst.
#   tmux  — redraw-proof banner on a 2nd status line (visible over SSH)
#   dunst — persistent desktop notify-send carrying a tmux jump target
# Mode resolves from $AGENT_NOTIFY_MODE > $XDG_CONFIG_HOME/agent-notify/mode >
# 'tmux' (default). Flip it with agent-notify-mode.sh.
#
# Whenever running inside tmux the jump target is written to
# $XDG_CACHE_HOME/tmux-jump/active (lines: window_id, notify_id, pane_id) so the
# `prefix+g` binding can jump to the pane that fired — independent of backend.
#
# Usage: agent-notify.sh <app-label> <event>     event = stop | notification
# Notification event reads the hook JSON payload (.message) from stdin.
# Used by claude-notify.sh ("Claude Code") and gemini-notify.sh ("Gemini").
# Emits nothing on stdout, so callers that must keep stdout clean can rely on it.

set -u

# shellcheck source=/dev/null
. "$(dirname "$0")/agent-notify-lib.sh"

app="${1:-Agent}"
event="${2:-stop}"

# --- event -> body / urgency / style -----------------------------------------
case "$event" in
	stop)
		urgency="low"
		body="Turn complete"
		title="✓ $app — turn complete"
		style="bg=colour28,fg=colour231,bold"
		ms=6000
		;;
	notification)
		body=$(jq -r '.message // "Input needed"')
		urgency="critical"
		title="● $app — input needed"
		style="bg=colour196,fg=colour231,bold"
		ms=10000
		;;
	*)
		urgency="low"
		body="$event"
		title="● $app"
		style="bg=colour240,fg=colour231,bold"
		ms=6000
		;;
esac

mode=$(an_mode)

# --- tmux jump context -------------------------------------------------------
loc=""; tgt=""; pane="${TMUX_PANE:-}"
if [ -n "$pane" ] && command -v tmux >/dev/null 2>&1; then
	loc=$(tmux display-message -p -t "$pane" '#S:#W' 2>/dev/null || true)
	tgt=$(tmux display-message -p -t "$pane" '#{window_id}' 2>/dev/null || true)
fi

# --- fire the active backend -------------------------------------------------
state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-jump"
state_file="$state_dir/active"
new_id=""

if [ "$mode" = "tmux" ]; then
	# Build the banner content. The status line is a tmux FORMAT, so literal '#'
	# must be doubled; the #[...] style sequences are intentional.
	bloc=""; [ -n "$loc" ] && bloc=" [$loc]"
	sbody=${body//#/##}
	sbloc=${bloc//#/##}
	an_tmux_banner "#[$style] $title$sbloc #[default] $sbody" "$ms"
elif [ "$mode" = "dunst" ]; then
	if [ -n "$tgt" ]; then
		mkdir -p "$state_dir"
		prev_id=""
		[ -f "$state_file" ] && prev_id=$(awk 'NR==2 {print; exit}' "$state_file" 2>/dev/null || true)
		new_id=$(an_dunst "$app" "$urgency" "$app [$loc]" "$body" "$prev_id" "tmux-target:$tgt")
	else
		new_id=$(an_dunst "$app" "$urgency" "$app" "$body" "" "")
	fi
fi

# --- jump state file: written whenever in tmux, independent of backend -------
if [ -n "$tgt" ]; then
	mkdir -p "$state_dir"
	printf '%s\n%s\n%s\n' "$tgt" "$new_id" "$pane" > "$state_file"
fi

exit 0
