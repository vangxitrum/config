#!/usr/bin/env bash
# Shared agent Stop/Notification hook for Claude Code and Gemini CLI.
#
# One backend is active at a time (the toggle): tmux | dunst.
#   tmux  — redraw-proof banner on a 2nd status line (visible over SSH)
#   dunst — persistent desktop notify-send carrying a tmux jump target
# Mode resolves from $AGENT_NOTIFY_MODE > $XDG_CONFIG_HOME/agent-notify/mode >
# 'tmux' (default). Flip it with agent-notify-mode.sh.
#
# Whenever running inside tmux the jump target is written to
# $XDG_CACHE_HOME/tmux-jump/active (lines: window_id, notify_id, pane_id) so the
# `prefix+g` binding can jump to the pane that fired — independent of backend.
#
# Usage: agent-notify.sh <app-label> <event>     event = stop | notification
# Notification event reads the hook JSON payload (.message) from stdin.
# Used by claude-notify.sh ("Claude Code") and gemini-notify.sh ("Gemini").
# Emits nothing on stdout, so callers that must keep stdout clean can rely on it.

set -u

# shellcheck source=/dev/null
. "$(dirname "$0")/agent-notify-lib.sh"

app="${1:-Agent}"
event="${2:-stop}"

# --- event -> body / urgency / style -----------------------------------------
case "$event" in
	stop)
		urgency="low"
		body="Turn complete"
		title="✓ $app — turn complete"
		style="bg=colour28,fg=colour231,bold"
		ms=6000
		;;
	notification)
		body=$(jq -r '.message // "Input needed"')
		urgency="critical"
		title="● $app — input needed"
		style="bg=colour196,fg=colour231,bold"
		ms=10000
		;;
	*)
		urgency="low"
		body="$event"
		title="● $app"
		style="bg=colour240,fg=colour231,bold"
		ms=6000
		;;
esac

mode=$(an_mode)

# --- tmux jump context -------------------------------------------------------
loc=""; tgt=""; pane="${TMUX_PANE:-}"
if [ -n "$pane" ] && command -v tmux >/dev/null 2>&1; then
	loc=$(tmux display-message -p -t "$pane" '#S:#W' 2>/dev/null || true)
	tgt=$(tmux display-message -p -t "$pane" '#{window_id}' 2>/dev/null || true)
fi

# --- fire the active backend -------------------------------------------------
state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-jump"
state_file="$state_dir/active"
new_id=""

if [ "$mode" = "tmux" ]; then
	# Build the banner content. The status line is a tmux FORMAT, so literal '#'
	# must be doubled; the #[...] style sequences are intentional.
	bloc=""; [ -n "$loc" ] && bloc=" [$loc]"
	sbody=${body//#/##}
	sbloc=${bloc//#/##}
	an_tmux_banner "#[$style] $title$sbloc #[default] $sbody" "$ms"
elif [ "$mode" = "dunst" ]; then
	if [ -n "$tgt" ]; then
		mkdir -p "$state_dir"
		prev_id=""
		[ -f "$state_file" ] && prev_id=$(awk 'NR==2 {print; exit}' "$state_file" 2>/dev/null || true)
		new_id=$(an_dunst "$app" "$urgency" "$app [$loc]" "$body" "$prev_id" "tmux-target:$tgt")
	else
		new_id=$(an_dunst "$app" "$urgency" "$app" "$body" "" "")
	fi
fi

# --- jump state file: written whenever in tmux, independent of backend -------
if [ -n "$tgt" ]; then
	mkdir -p "$state_dir"
	printf '%s\n%s\n%s\n' "$tgt" "$new_id" "$pane" > "$state_file"
fi

# --- live per-window tab indicator (agent-state.sh) --------------------------
# stop -> clear the tab; notification -> show the "needs input" icon. Keyed to
# this pane's window via $TMUX_PANE (same as the jump context above).
#
# Exception: Claude Code fires a generic "waiting for your input" notification at
# turn end (idle prompt), NOT a real permission request. Treat that like stop and
# clear the tab, so a finished agent doesn't leave a stuck "needs input" badge.
# A genuine permission prompt ("… needs your permission …") still shows the icon.
if [ -n "$tgt" ]; then
	case "$event" in
		stop)
			"$(dirname "$0")/agent-state.sh" idle >/dev/null 2>&1 || true ;;
		notification)
			case "$body" in
				*[Ww]aiting\ for\ your\ input*|*[Ww]aiting\ for\ input*)
					"$(dirname "$0")/agent-state.sh" idle >/dev/null 2>&1 || true ;;
				*)
					"$(dirname "$0")/agent-state.sh" input "$body" >/dev/null 2>&1 || true ;;
			esac ;;
	esac
fi

# --- terminal window title: reset it when the turn is done -------------------
# The agent sets its pane title (e.g. "⠐ Claude Code") while working; set-titles
# mirrors #{pane_title} into the terminal title. On stop, replace that stale
# title with the pane's current directory instead of blanking it — blanking also
# empties #{pane_title} in choose-tree (prefix+w) and pane-border-format, hiding
# useful info. The dir keeps the terminal title clean AND the picker readable.
if [ -n "$pane" ] && [ "$event" = "stop" ]; then
	dir=$(tmux display-message -p -t "$pane" '#{b:pane_current_path}' 2>/dev/null)
	tmux select-pane -t "$pane" -T "${dir:-shell}" >/dev/null 2>&1 || true
fi

exit 0
