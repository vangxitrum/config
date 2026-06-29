#!/usr/bin/env bash
# Shared notification primitives for agent-notify.sh and agent-notify-mode.sh.
# Sourced, not executed. Two backends:
#   tmux  — a redraw-proof banner on a dedicated 2nd status line. (A plain
#           display-message toast is wiped by the next status redraw, which in a
#           busy session is near-instant; a status-line value survives redraws.)
#   dunst — notify-send -t 0 (never auto-expire) with -r to replace in place.

# Resolve the active mode -> prints 'tmux' or 'dunst' (default tmux).
an_mode() {
	local m="${AGENT_NOTIFY_MODE:-}"
	local f="${XDG_CONFIG_HOME:-$HOME/.config}/agent-notify/mode"
	[ -z "$m" ] && [ -r "$f" ] && m=$(tr -d '[:space:]' < "$f" 2>/dev/null || true)
	case "$m" in tmux|dunst) printf '%s' "$m" ;; *) printf 'tmux' ;; esac
}

an_set_mode() {  # $1 = tmux|dunst
	local f="${XDG_CONFIG_HOME:-$HOME/.config}/agent-notify/mode"
	mkdir -p "$(dirname "$f")"
	printf '%s\n' "$1" > "$f"
}

# Show a banner on a dedicated 2nd tmux status line; auto-clears after $2 ms.
#   $1 = fully styled content (may contain #[...] sequences)
#   $2 = milliseconds to hold (default 8000)
# A newer banner replaces the current one (and resets the timer) via a token,
# so the clear job never removes a banner that has since been replaced.
an_tmux_banner() {
	[ -n "${TMUX:-}" ] || return 0
	command -v tmux >/dev/null 2>&1 || return 0
	tmux list-clients >/dev/null 2>&1 || return 0

	local content="$1" ms="${2:-8000}"
	local sec=$(( ms / 1000 )); [ "$sec" -lt 1 ] && sec=1
	local token="$$-$ms-${RANDOM:-0}"

	# Save the user's normal status value once, so concurrent banners don't
	# stack saves and lose the real value.
	if [ "$(tmux show -gv '@agent_notify_active' 2>/dev/null)" != "1" ]; then
		tmux set -g '@agent_notify_prev_status' "$(tmux show -gv status)"
		tmux set -g '@agent_notify_active' "1"
	fi
	tmux set -g '@agent_notify_token' "$token"
	tmux set -g '@agent_notify' "$content"
	tmux set -g 'status-format[1]' "#{@agent_notify}"
	tmux set -g status 2

	# Detached auto-clear: only clears if our token still owns the banner.
	local clear_job='
		sleep "$1"
		[ "$(tmux show -gv @agent_notify_token 2>/dev/null)" = "$2" ] || exit 0
		prev=$(tmux show -gv @agent_notify_prev_status 2>/dev/null); [ -z "$prev" ] && prev=on
		tmux set -gu "status-format[1]" 2>/dev/null
		tmux set -g status "$prev" 2>/dev/null
		tmux set -g @agent_notify "" 2>/dev/null
		tmux set -g @agent_notify_active "0" 2>/dev/null
	'
	if command -v setsid >/dev/null 2>&1; then
		setsid -f bash -c "$clear_job" _ "$sec" "$token" >/dev/null 2>&1 &
	else
		nohup bash -c "$clear_job" _ "$sec" "$token" >/dev/null 2>&1 &
	fi
}

# Send a desktop notification via dunst. Prints the new notification id.
#   $1 app  $2 urgency  $3 summary  $4 body  $5 replace-id(optional)  $6 category(optional)
# -t 0 = never auto-expire (stays until dismissed or replaced).
an_dunst() {
	command -v notify-send >/dev/null 2>&1 || return 0
	local args=(-a "$1" -u "$2" -t 0 -p)
	[ -n "${6:-}" ] && args+=(-c "$6")
	[ -n "${5:-}" ] && args+=(-r "$5")
	notify-send "${args[@]}" "$3" "$4" 2>/dev/null || true
}
