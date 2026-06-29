#!/usr/bin/env bash
# Antigravity CLI (agy) Stop/Notification hook. Thin shim over agent-notify.sh.
# Like Gemini, agy may read the hook's stdout, so keep stdout to valid JSON only:
# suppress the core's (empty) stdout and emit {}.
# Usage: antigravity-notify.sh <event>     event = stop | notification
"$(dirname "$0")/agent-notify.sh" "Antigravity" "${1:-stop}" >/dev/null 2>&1
printf '{}\n'
