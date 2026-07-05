#!/usr/bin/env bash
# Cached weather segment for the tmux status line.
# Prints "<condition-emoji><temp>" for Ho Chi Minh City, e.g. "☀️+31°C".
#
# Fetches from wttr.in but NEVER blocks the status render: it prints whatever is
# cached immediately, and only when the cache is stale does it kick off a
# background curl to refresh it. First ever call (no cache) prints "…" until the
# background fetch lands (a few seconds later).
set -u

LOC="${TMUX_WEATHER_LOC:-Ho_Chi_Minh}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-weather"
MAX_AGE=1800   # seconds (30 min) before a refresh is triggered

now=$(date +%s)
mtime=0
[ -f "$CACHE" ] && mtime=$(stat -c %Y "$CACHE" 2>/dev/null || echo 0)

if [ $(( now - mtime )) -ge "$MAX_AGE" ]; then
	# Refresh in the background; do not wait on the network.
	(
		out=$(curl -fsS -m 5 "https://wttr.in/${LOC}?format=%c%t" 2>/dev/null | tr -d '\n ')
		case "$out" in
			*[Uu]nknown*|'') : ;;                       # keep old cache on error
			*) printf '%s' "$out" > "$CACHE" ;;
		esac
	) >/dev/null 2>&1 &
fi

if [ -s "$CACHE" ]; then cat "$CACHE"; else printf '…'; fi
