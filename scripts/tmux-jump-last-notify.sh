#!/usr/bin/env bash
# Jump to the tmux window referenced by the currently-active notification
# tracked in $XDG_CACHE_HOME/tmux-jump/active (three lines: window_id, notify_id, pane_id).
#
# - Jumps to the window inside tmux (uses $TMUX if set, otherwise routes
#   through any attached client and focuses the terminal workspace).
# - Closes the notification by id via the standard notifications dbus.
# - Removes the state file so a second press without a new notification is a
#   "nothing to jump to" no-op.
#
# The matching close binding in i3 (Control+n) also removes the state file so
# that a user-dismissed notification cannot later be jumped to.

set -u

fail() {
	notify-send -a "tmux-jump" -u low "tmux jump" "$1" 2>/dev/null || true
	exit 0
}

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-jump"
state_file="$state_dir/active"

[ -s "$state_file" ] || fail "No active notification to jump to."

target=$(awk 'NR==1 {print; exit}' "$state_file")
notify_id=$(awk 'NR==2 {print; exit}' "$state_file")
pane_id=$(awk 'NR==3 {print; exit}' "$state_file")

if [ -z "$target" ]; then
	rm -f "$state_file"
	fail "State file is corrupt."
fi

if ! tmux list-windows -a -F '#{window_id}' 2>/dev/null | grep -qx "$target"; then
	rm -f "$state_file"
	fail "Target $target no longer exists."
fi

if [ -n "${TMUX:-}" ]; then
	# Save origin (window + pane) so C-s b can return here.
	tmux display-message -p '#{window_id}
#{pane_id}' > "$state_dir/origin"
	tmux switch-client -t "$target"
else
	# Save origin (window + pane) from the first attached client.
	origin_win=$(tmux list-clients -F '#{window_id}' 2>/dev/null | head -1)
	origin_pane=$(tmux list-clients -F '#{pane_id}' 2>/dev/null | head -1)
	printf '%s\n%s\n' "$origin_win" "$origin_pane" > "$state_dir/origin"

	i3-msg 'workspace number 1:terminal' >/dev/null 2>&1 || true
	clients=$(tmux list-clients -F '#{client_tty}' 2>/dev/null || true)
	if [ -n "$clients" ]; then
		while IFS= read -r tty; do
			[ -n "$tty" ] && tmux switch-client -c "$tty" -t "$target"
		done <<< "$clients"
	else
		session=$(tmux list-windows -a -F '#{window_id} #{session_name}' \
			| awk -v t="$target" '$1==t {print $2; exit}')
		[ -z "$session" ] && fail "Could not resolve session for $target."
		ghostty -e bash -lc "tmux attach -t '$session' \\; select-window -t '$target'" \
			>/dev/null 2>&1 &
	fi
fi

# Select the exact pane if it still exists.
if [ -n "${pane_id:-}" ]; then
	tmux select-pane -t "$pane_id" 2>/dev/null || true
fi

if [ -n "$notify_id" ]; then
	gdbus call --session \
		--dest org.freedesktop.Notifications \
		--object-path /org/freedesktop/Notifications \
		--method org.freedesktop.Notifications.CloseNotification "$notify_id" \
		>/dev/null 2>&1 || true
fi
rm -f "$state_file"
