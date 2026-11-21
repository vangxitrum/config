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
#        clip.sh --paste          print the clipboard (nvim's paste provider)
#
# --paste reads this host's X clipboard when there is one. Otherwise (the
# coding container, SSH) it asks the terminal I am typing in for its clipboard
# via OSC 52 through tmux (`refresh-client -l`); kitty and Ghostty ask before
# answering by default. Without an answer it falls back to tmux's last buffer.

if [ "$1" = "--paste" ]; then
	if [ -n "$DISPLAY" ] && command -v xclip >/dev/null 2>&1 &&
		xclip -o -selection clipboard 2>/dev/null; then
		exit 0
	fi
	[ -n "$TMUX" ] || exit 0
	top() { tmux list-buffers -F '#{buffer_name}' 2>/dev/null | head -n1; }
	before=$(top)
	tmux refresh-client -l 2>/dev/null
	# The answer arrives asynchronously as a new paste buffer. Wait up to 5s,
	# long enough to click a terminal's "allow" prompt.
	for _ in $(seq 50); do
		[ "$(top)" != "$before" ] && break
		sleep 0.1
	done
	tmux save-buffer - 2>/dev/null
	exit 0
fi

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
