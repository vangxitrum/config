#!/usr/bin/env bash
# Shared notification primitives for agent-notify.sh and agent-notify-mode.sh.
# Sourced, not executed. Two backends:
#   tmux  — a redraw-proof banner that temporarily replaces status-right (same
#           row, so panes never shift). Works over SSH / inside the container.
#           (A plain display-message toast is wiped by the next status redraw;
#           a status-line value survives redraws.)
#   dunst — notify-send -t 0 (never auto-expire) with -r to replace in place.

# Resolve the active mode -> prints 'tmux' or 'dunst' (default tmux, also in
# the coding container: over SSH nothing reads the dunst bridge spool).
an_mode() {
	local m="${AGENT_NOTIFY_MODE:-}"
	local f="${XDG_CONFIG_HOME:-$HOME/.config}/agent-notify/mode"
	[ -z "$m" ] && [ -r "$f" ] && m=$(tr -d '[:space:]' < "$f" 2>/dev/null || true)
	case "$m" in tmux|dunst) printf '%s' "$m" ;; *) printf 'tmux' ;; esac
}

# True when notifications should go through the host bridge
# (compose.coding.yaml sets AGENT_NOTIFY_SPOOL to a mount of the host's
# $XDG_RUNTIME_DIR/agent-notify, read by agent-notify-bridge.sh).
an_spool_ok() {
	[ -n "${AGENT_NOTIFY_SPOOL:-}" ] && [ -d "$AGENT_NOTIFY_SPOOL" ] && [ -w "$AGENT_NOTIFY_SPOOL" ]
}

# Ask the host bridge to close the notification it showed last (it keeps the
# id; the container never sees it). No-op outside the container.
an_spool_close() {
	an_spool_ok || return 0
	: > "$AGENT_NOTIFY_SPOOL/$(date +%s%N).$$.close" 2>/dev/null || true
}

# On the host: print the id of the running coding container
# (compose.coding.yaml), or nothing. Its tmux server and jump state live in
# there, not on the host.
an_coding_container() {
	an_spool_ok && return 0  # already inside it
	command -v docker >/dev/null 2>&1 || return 0
	docker ps -q --filter label=com.docker.compose.service=coding \
		--filter ancestor=config-coding:latest 2>/dev/null | head -n1
}

an_set_mode() {  # $1 = tmux|dunst
	local f="${XDG_CONFIG_HOME:-$HOME/.config}/agent-notify/mode"
	mkdir -p "$(dirname "$f")"
	printf '%s\n' "$1" > "$f"
}

# Show a banner in place of status-right; auto-clears after $2 ms.
#   $1 = fully styled content (may contain #[...] sequences)
#   $2 = milliseconds to hold (default 8000)
# Reuses the existing status row (no 2nd line), so panes never shift. The
# banner is a status-line value, so it survives redraws (a display-message
# toast would not). A newer banner replaces the current one (and resets the
# timer) via a token, so the clear job never removes a newer banner.
an_tmux_banner() {
	[ -n "${TMUX:-}" ] || return 0
	command -v tmux >/dev/null 2>&1 || return 0
	tmux list-clients >/dev/null 2>&1 || return 0

	local content="$1" ms="${2:-8000}"
	local sec=$(( ms / 1000 )); [ "$sec" -lt 1 ] && sec=1
	local token="$$-$ms-${RANDOM:-0}"

	# Save the user's status-right once, so concurrent banners don't stack
	# saves and lose the real value.
	if [ "$(tmux show -gv '@agent_notify_active' 2>/dev/null)" != "1" ]; then
		tmux set -g '@agent_notify_prev_right' "$(tmux show -gv status-right)"
		tmux set -g '@agent_notify_prev_right_len' "$(tmux show -gv status-right-length)"
		tmux set -g '@agent_notify_active' "1"
	fi
	tmux set -g '@agent_notify_token' "$token"
	tmux set -g '@agent_notify' "$content"
	tmux set -g status-right-length 200
	tmux set -g status-right "#{@agent_notify}"
	tmux refresh-client -S 2>/dev/null || true

	# Detached auto-clear: only clears if our token still owns the banner.
	local clear_job='
		sleep "$1"
		[ "$(tmux show -gv @agent_notify_token 2>/dev/null)" = "$2" ] || exit 0
		tmux set -g status-right "$(tmux show -gv @agent_notify_prev_right 2>/dev/null)" 2>/dev/null
		len=$(tmux show -gv @agent_notify_prev_right_len 2>/dev/null); [ -z "$len" ] && len=40
		tmux set -g status-right-length "$len" 2>/dev/null
		tmux set -g @agent_notify "" 2>/dev/null
		tmux set -g @agent_notify_active "0" 2>/dev/null
		tmux refresh-client -S 2>/dev/null
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
	if an_spool_ok; then
		# Host bridge: no notification id comes back, so no replace (-r).
		# Write under a temp name and rename, so the bridge never reads half a file.
		local tmp="$AGENT_NOTIFY_SPOOL/.$$.${RANDOM:-0}.tmp"
		printf '%s\n%s\n%s\n%s\n' "$1" "$2" "$3" "$4" > "$tmp" 2>/dev/null &&
			chmod 644 "$tmp" &&
			mv -f "$tmp" "$AGENT_NOTIFY_SPOOL/$(date +%s%N).$$.msg" 2>/dev/null || rm -f "$tmp"
		return 0
	fi
	command -v notify-send >/dev/null 2>&1 || return 0
	local args=(-a "$1" -u "$2" -t 0 -p)
	[ -n "${6:-}" ] && args+=(-c "$6")
	[ -n "${5:-}" ] && args+=(-r "$5")
	notify-send "${args[@]}" "$3" "$4" 2>/dev/null || true
}
