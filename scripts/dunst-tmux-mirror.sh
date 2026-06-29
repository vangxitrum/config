#!/usr/bin/env bash
# Mirror desktop (dunst) notifications onto the tmux 2nd status line, so they
# stay visible over SSH where dunst's GUI popups are not.
#
# Polls `dunstctl history` and, for each newly-arrived notification, renders a
# banner via the shared an_tmux_banner (status-format[1]) — the same redraw-proof,
# Dracula-compatible slot the agent-notify hooks already use.
#
# Run it ON the PC (not from the SSH session) so it survives across logins; a
# systemd --user service is the intended launcher (see dunst-tmux-mirror.service).
#
# Tunables (env):
#   DUNST_TMUX_INTERVAL  poll seconds        (default 2)
#   DUNST_TMUX_HOLD_MS   banner hold in ms   (default 8000)
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=agent-notify-lib.sh
. "$DIR/agent-notify-lib.sh"

# Banner painter for this daemon. Mirrors agent-notify-lib's an_tmux_banner
# exactly — same @agent_notify_* global protocol, token, and detached restore —
# so mirror banners and agent banners never clobber each other. The ONE change:
# gate on "a client is attached" instead of "$TMUX is set", because this daemon
# runs OUTSIDE tmux (systemd/SSH), where an_tmux_banner would early-return.
mirror_banner() {
	command -v tmux >/dev/null 2>&1 || return 0
	tmux list-clients >/dev/null 2>&1 || return 0
	[ -n "$(tmux list-clients 2>/dev/null)" ] || return 0

	local content="$1" ms="${2:-8000}"
	local sec=$(( ms / 1000 )); [ "$sec" -lt 1 ] && sec=1
	local token="$$-$ms-${RANDOM:-0}"

	if [ "$(tmux show -gv '@agent_notify_active' 2>/dev/null)" != "1" ]; then
		tmux set -g '@agent_notify_prev_status' "$(tmux show -gv status)"
		tmux set -g '@agent_notify_active' "1"
	fi
	tmux set -g '@agent_notify_token' "$token"
	tmux set -g '@agent_notify' "$content"
	tmux set -g 'status-format[1]' "#{@agent_notify}"
	tmux set -g status 2

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

# Reach the graphical session's bus even when launched outside it (SSH/systemd).
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

INTERVAL="${DUNST_TMUX_INTERVAL:-2}"
HOLD_MS="${DUNST_TMUX_HOLD_MS:-8000}"

newest_id() { dunstctl history 2>/dev/null | jq -r '.data[0][0].id.data // empty'; }

# Seed with the current newest so we don't replay a stale notification on start.
last="$(newest_id)"

while :; do
	hist="$(dunstctl history 2>/dev/null)" || { sleep "$INTERVAL"; continue; }

	IFS=$'\t' read -r id app summary <<-EOF
	$(printf '%s' "$hist" | jq -r '
		.data[0][0] // empty
		| [ (.id.data | tostring), (.appname.data // "notify"), (.summary.data // "") ]
		| @tsv')
	EOF

	if [ -n "${id:-}" ] && [ "$id" != "$last" ]; then
		last="$id"
		content="#[bg=#bd93f9,fg=#282a36,bold] 🔔 ${app} #[bg=#44475a,fg=#f8f8f2,nobold] ${summary} #[default]"
		mirror_banner "$content" "$HOLD_MS"
	fi

	sleep "$INTERVAL"
done
