#!/usr/bin/env bash
# agent-notify-bridge.sh - show notifications from the coding container on the
# host's dunst.
#
# The container (compose.coding.yaml) has no D-Bus link to the host, and under
# rootless Docker its `coder` user is a subuid that the session bus would
# refuse anyway. So agent-notify-lib.sh's an_dunst writes each notification
# as a file into $AGENT_NOTIFY_SPOOL (/run/agent-notify in the container, a bind
# mount of $XDG_RUNTIME_DIR/agent-notify), and this watcher, running on the
# host, hands each one to notify-send and deletes it.
#
# File format: line 1 app, line 2 urgency, line 3 summary, the rest is the body.
# An empty *.close file closes the last notification shown here (sent by
# tmux-jump-last-notify.sh after a jump inside the container).
#
# Started by i3 (config/i3/config); safe to start again, only one instance runs.
set -u

runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
spool="${AGENT_NOTIFY_BRIDGE_DIR:-$runtime/agent-notify}"
interval="${AGENT_NOTIFY_BRIDGE_INTERVAL:-1}"

# World-writable because the container's user is a subuid on the host; still
# private, since $XDG_RUNTIME_DIR itself is 0700.
mkdir -p "$spool"
chmod 0777 "$spool"

exec 9>"$runtime/agent-notify-bridge.lock"
flock -n 9 || exit 0

command -v notify-send >/dev/null || { echo "agent-notify-bridge: notify-send not found" >&2; exit 1; }

last_id=""

while :; do
	for f in "$spool"/*.close; do
		[ -f "$f" ] || continue
		rm -f "$f"
		[ -n "$last_id" ] && gdbus call --session \
			--dest org.freedesktop.Notifications \
			--object-path /org/freedesktop/Notifications \
			--method org.freedesktop.Notifications.CloseNotification "$last_id" \
			>/dev/null 2>&1
		last_id=""
	done
	for f in "$spool"/*.msg; do
		[ -f "$f" ] || continue
		{
			IFS= read -r app
			IFS= read -r urgency
			IFS= read -r summary
			body=$(cat)
		} <"$f"
		rm -f "$f"
		case "$urgency" in low | normal | critical) ;; *) urgency=normal ;; esac
		last_id=$(notify-send -p -a "${app:-agent}" -u "$urgency" -t 0 "${summary:-${app:-agent}}" "$body" 2>/dev/null) || last_id=""
	done
	sleep "$interval"
done
