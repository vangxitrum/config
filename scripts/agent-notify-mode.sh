#!/usr/bin/env bash
# Show, set, or toggle the agent notification backend used by agent-notify.sh
# (shared by Claude Code and Gemini). Binary: tmux <-> dunst.
# After changing it, the new mode is ANNOUNCED through that very backend — no
# separate UI — which doubles as a self-test of the channel.
#
# Usage:
#   agent-notify-mode.sh            # print current mode
#   agent-notify-mode.sh show
#   agent-notify-mode.sh tmux|dunst # set mode
#   agent-notify-mode.sh toggle     # flip tmux <-> dunst
#
# Bind in tmux:  bind-key N run-shell '~/work/config/scripts/agent-notify-mode.sh toggle'

set -u

# shellcheck source=/dev/null
. "$(dirname "$0")/agent-notify-lib.sh"

arg="${1:-show}"
case "$arg" in
	show|status|"") : ;;
	tmux|dunst) an_set_mode "$arg" ;;
	toggle|cycle)
		if [ "$(an_mode)" = "tmux" ]; then an_set_mode dunst; else an_set_mode tmux; fi
		;;
	*)
		echo "usage: agent-notify-mode.sh [show|tmux|dunst|toggle]" >&2
		exit 2
		;;
esac

new=$(an_mode)

# Announce the active backend THROUGH that backend (no separate UI).
if [ "$arg" != "show" ] && [ "$arg" != "status" ] && [ -n "$arg" ]; then
	if [ "$new" = "tmux" ]; then
		an_tmux_banner "#[bg=colour33,fg=colour231,bold] 🔔 notifications: TMUX active #[default]" 3000
	else
		an_dunst "agent-notify" "normal" "Notifications: dunst" "dunst is now the active backend" "" "" >/dev/null
	fi
fi

printf '%s\n' "$new"
