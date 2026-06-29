#!/usr/bin/env bash
# Claude Code Stop/Notification hook. Thin shim over agent-notify.sh.
# Usage: claude-notify.sh <event>     event = stop | notification
exec "$(dirname "$0")/agent-notify.sh" "Claude Code" "${1:-stop}"
