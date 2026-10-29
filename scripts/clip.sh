#!/usr/bin/env bash
# Copy stdin to the clipboard of the terminal I am typing in, even over SSH.
#
# The text goes out as an OSC 52 escape, which the terminal on the machine I
# ssh'd from (Ghostty allows it by default) puts on its own clipboard. Inside
# tmux, `load-buffer -w` hands it to tmux, which sends OSC 52 to every attached
# client (needs `set-clipboard on`, see tmux.conf). It is also written to this
# host's X clipboard when one is reachable, so local pastes stay in sync.
#
# Usage: <cmd> | clip.sh          OSC 52 + X clipboard
#        <cmd> | clip.sh --x11    X clipboard only (tmux copy-pipe already sent OSC 52)

buf=$(mktemp)
trap 'rm -f "$buf"' EXIT
cat >"$buf"

if [ "$1" != "--x11" ]; then
	if [ -n "$TMUX" ]; then
		tmux load-buffer -w - <"$buf"
	elif [ -w /dev/tty ]; then
		printf '\033]52;c;%s\a' "$(base64 -w0 <"$buf")" >/dev/tty
	fi
fi

# xclip forks to own the selection; detach its stdio so callers do not hang.
if [ -n "$DISPLAY" ] && command -v xclip >/dev/null 2>&1; then
	xclip -selection clipboard <"$buf" >/dev/null 2>&1 || true
fi
