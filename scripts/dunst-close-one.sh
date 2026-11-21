#!/usr/bin/env bash
dunstctl close
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/tmux-jump/active"
# Same for the coding container's agents (their state lives in there).
. "$(dirname "$0")/agent-notify-lib.sh"
cid=$(an_coding_container)
[ -n "$cid" ] && docker exec "$cid" sh -c 'rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/tmux-jump/active"' >/dev/null 2>&1
exit 0
