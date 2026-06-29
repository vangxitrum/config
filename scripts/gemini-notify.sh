#!/usr/bin/env bash
# Gemini CLI Notification/AfterAgent hook. Thin shim over agent-notify.sh.
# Gemini requires hooks to print nothing on stdout except valid JSON
# ("silence is mandatory"), so suppress the core's (empty) stdout and emit {}.
# Usage: gemini-notify.sh <event>     event = stop | notification
"$(dirname "$0")/agent-notify.sh" "Gemini" "${1:-stop}" >/dev/null 2>&1
printf '{}\n'
