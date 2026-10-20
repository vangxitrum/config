#!/usr/bin/env bash
# OpenCode event adapter. Thin shim over agent-notify.sh.
# Usage: opencode-notify.sh <event> [message]

set -u

event="${1:-stop}"
script_dir=$(dirname "$0")

if [ "$event" = "notification" ]; then
	jq -cn --arg message "${2:-Input needed}" '{message: $message}' \
		| "$script_dir/agent-notify.sh" "OpenCode" notification >/dev/null 2>&1
	exit 0
fi

exec "$script_dir/agent-notify.sh" "OpenCode" "$event"
