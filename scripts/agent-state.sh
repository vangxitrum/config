#!/usr/bin/env bash
# Live per-window "agent activity" indicator for tmux.
#
# Companion to agent-notify.sh. Where that fires one-shot notifications, this
# maintains a PERSISTENT per-window state so a tmux tab can show, at a glance,
# which window has an agent actively working — with an animated emoji spinner,
# a distinct "needs your input" icon, and a token/cost readout.
#
# State lives in tmux WINDOW-scoped user options (no files, no races; freed
# automatically when the window closes). window-status-format references
# #{@agent_seg}, which tmux evaluates in each window's own context:
#
#   @agent_state : working | input | ''(idle)   (drives the animation daemon)
#   @agent_app   : "Claude Code" | "Gemini"      (informational)
#   @agent_meta  : e.g. "62% $0.42"  (ctx% + cost, pushed by the statusLine cmd)
#   @agent_seg   : the rendered tab segment #{@agent_seg} shows
#
# Usage (all resolve the target window from $TMUX_PANE, or $AGENT_WIN):
#   agent-state.sh working [app]   # turn started -> animate; ensures daemon up
#   agent-state.sh input   [app]   # agent paused, needs input -> static icon
#   agent-state.sh idle            # turn done / cleared -> blank the tab
#   agent-state.sh meta  "<str>"   # set @agent_meta for the current window
#   agent-state.sh daemon          # (internal) the ~7fps animation loop
#
# Wired from: Claude Code UserPromptSubmit (working), agent-notify.sh
# (input/idle), and statusline-command.sh (meta).

set -u

SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-agent"
LOCK_FILE="$CACHE_DIR/daemon.lock"

INTERVAL=0.15   # seconds between animation frames (~7 fps)
IDLE_TICKS=3    # exit the daemon after this many ticks with nothing working
STALE_EVERY=20  # run the crash/staleness check every N ticks (~3s)
STALE_STRIKES=2 # clear a working window after this many consecutive misses

# --- prerequisites -----------------------------------------------------------
command -v tmux >/dev/null 2>&1 || exit 0
[ -n "${TMUX:-}" ] || exit 0

# Configurable glyphs (with sensible defaults) --------------------------------
_frames_str=$(tmux show -gqv '@agent_frames' 2>/dev/null)
[ -z "$_frames_str" ] && _frames_str='🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘'
# shellcheck disable=SC2206
read -r -a FRAMES <<<"$_frames_str"
[ "${#FRAMES[@]}" -eq 0 ] && FRAMES=('●')

INPUT_ICON=$(tmux show -gqv '@agent_input_icon' 2>/dev/null)
[ -z "$INPUT_ICON" ] && INPUT_ICON='🔔'

# Short text labels shown next to the glyph (configurable in tmux.conf).
LABEL_WORKING=$(tmux show -gqv '@agent_label_working' 2>/dev/null)
[ -z "$LABEL_WORKING" ] && LABEL_WORKING='working'
LABEL_INPUT=$(tmux show -gqv '@agent_label_input' 2>/dev/null)
[ -z "$LABEL_INPUT" ] && LABEL_INPUT='needs input'
MAXLABEL=$(tmux show -gqv '@agent_label_max' 2>/dev/null)
[ -z "$MAXLABEL" ] && MAXLABEL=32

# --- helpers -----------------------------------------------------------------

# Resolve the target window_id: explicit $AGENT_WIN, else from $TMUX_PANE.
_win() {
	if [ -n "${AGENT_WIN:-}" ]; then printf '%s' "$AGENT_WIN"; return; fi
	local pane="${TMUX_PANE:-}"
	[ -n "$pane" ] && tmux display-message -p -t "$pane" '#{window_id}' 2>/dev/null
}

# window-scoped get / set / unset of a user option
_wget() { tmux show -wqv -t "$1" "$2" 2>/dev/null; }              # $1=win $2=opt
_wset() { tmux set-option -w -t "$1" "$2" "$3" 2>/dev/null; }     # $1 $2 $3=val
_wunset() { tmux set-option -w -t "$1" -u "$2" 2>/dev/null; }

# Collapse whitespace and truncate a label to $MAXLABEL chars (adds an ellipsis).
_trunc() {  # $1=text
	local s; s=$(printf '%s' "$1" | tr '\n\t' '  ' | sed 's/  */ /g; s/^ //; s/ $//')
	if [ "${#s}" -gt "$MAXLABEL" ]; then printf '%s…' "${s:0:MAXLABEL-1}"; else printf '%s' "$s"; fi
}

# Compose the segment shown on the tab: glyph + short label + meta (ctx%/cost).
# Trailing/leading spaces give the emoji room next to the Dracula styling.
_compose() {  # $1=win  $2=glyph
	local label meta out
	label=$(_wget "$1" '@agent_label')
	meta=$(_wget "$1" '@agent_meta')
	out="$2"
	[ -n "$label" ] && out="$out $label"
	[ -n "$meta" ]  && out="$out $meta"
	printf ' %s ' "$out"
}

# Launch the animation daemon unless one is already alive.
_ensure_daemon() {
	local pid; pid=$(tmux show -gqv '@agent_daemon_pid' 2>/dev/null)
	[ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && return 0
	mkdir -p "$CACHE_DIR"
	# flock (inside the daemon) is the real single-instance guard; this is just
	# to avoid spawning a doomed process on every prompt.
	if command -v setsid >/dev/null 2>&1; then
		setsid -f bash "$SELF" daemon >/dev/null 2>&1 || \
			nohup bash "$SELF" daemon >/dev/null 2>&1 &
	else
		nohup bash "$SELF" daemon >/dev/null 2>&1 &
	fi
}

# --- subcommands -------------------------------------------------------------

cmd_working() {
	local win; win=$(_win); [ -n "$win" ] || exit 0
	_wset "$win" '@agent_state' 'working'
	_wset "$win" '@agent_app' "${1:-}"
	_wset "$win" '@agent_label' "$LABEL_WORKING"
	_wset "$win" '@agent_miss' '0'
	# Paint the first frame immediately so the tab reacts before the daemon ticks.
	_wset "$win" '@agent_seg' "$(_compose "$win" "${FRAMES[0]}")"
	_ensure_daemon
	tmux refresh-client -S 2>/dev/null || true
}

cmd_input() {
	local win; win=$(_win); [ -n "$win" ] || exit 0
	# Prefer the agent's actual notification message; fall back to a default label.
	local label; label=$(_trunc "${1:-}"); [ -z "$label" ] && label="$LABEL_INPUT"
	_wset "$win" '@agent_state' 'input'
	_wset "$win" '@agent_label' "$label"
	_wset "$win" '@agent_seg' "#[fg=colour214,bold]$(_compose "$win" "$INPUT_ICON")#[default]"
	tmux refresh-client -S 2>/dev/null || true
}

cmd_idle() {
	local win; win=$(_win); [ -n "$win" ] || exit 0
	_wunset "$win" '@agent_state'
	_wunset "$win" '@agent_seg'
	_wunset "$win" '@agent_meta'
	_wunset "$win" '@agent_label'
	_wunset "$win" '@agent_miss'
	tmux refresh-client -S 2>/dev/null || true
}

cmd_meta() {
	local win; win=$(_win); [ -n "$win" ] || exit 0
	_wset "$win" '@agent_meta' "${1:-}"
	# Keep the static input segment in sync; working is handled by the daemon.
	if [ "$(_wget "$win" '@agent_state')" = "input" ]; then
		_wset "$win" '@agent_seg' "#[fg=colour214,bold]$(_compose "$win" "$INPUT_ICON")#[default]"
		tmux refresh-client -S 2>/dev/null || true
	fi
}

# Does the given window still have a live claude/node process in any pane?
_win_has_agent() {  # $1=win
	tmux list-panes -t "$1" -F '#{pane_current_command}' 2>/dev/null \
		| grep -qiE '^(claude|node)$'
}

cmd_daemon() {
	mkdir -p "$CACHE_DIR"
	# Single-instance guard: whoever holds the lock is THE daemon.
	exec 9>"$LOCK_FILE"
	flock -n 9 || exit 0
	tmux set -g '@agent_daemon_pid' "$$" 2>/dev/null || true

	local counter=0 idle=0
	while true; do
		local any=0 stale_pass=0
		[ $(( counter % STALE_EVERY )) -eq 0 ] && stale_pass=1

		# One pass over every window in every session.
		while read -r wid state; do
			[ "$state" = "working" ] || continue

			if [ "$stale_pass" -eq 1 ] && ! _win_has_agent "$wid"; then
				local miss; miss=$(_wget "$wid" '@agent_miss'); miss=$(( ${miss:-0} + 1 ))
				if [ "$miss" -ge "$STALE_STRIKES" ]; then
					# Agent vanished without a Stop hook — clear this tab.
					_wunset "$wid" '@agent_state'
					_wunset "$wid" '@agent_seg'
					_wunset "$wid" '@agent_meta'
					_wunset "$wid" '@agent_label'
					_wunset "$wid" '@agent_miss'
					continue
				fi
				_wset "$wid" '@agent_miss' "$miss"
			elif [ "$stale_pass" -eq 1 ]; then
				_wset "$wid" '@agent_miss' '0'
			fi

			any=1
			local frame="${FRAMES[ counter % ${#FRAMES[@]} ]}"
			_wset "$wid" '@agent_seg' "$(_compose "$wid" "$frame")"
		done < <(tmux list-windows -a -F '#{window_id} #{@agent_state}' 2>/dev/null)

		if [ "$any" -eq 1 ]; then
			tmux refresh-client -S 2>/dev/null || true
			idle=0
		else
			idle=$(( idle + 1 ))
			[ "$idle" -ge "$IDLE_TICKS" ] && break
		fi

		counter=$(( counter + 1 ))
		sleep "$INTERVAL"
	done

	tmux set -g '@agent_daemon_pid' '' 2>/dev/null || true
}

# --- dispatch ----------------------------------------------------------------
case "${1:-}" in
	working) shift; cmd_working "${1:-}" ;;
	input)   shift; cmd_input   "${1:-}" ;;
	idle)    cmd_idle ;;
	meta)    shift; cmd_meta    "${1:-}" ;;
	daemon)  cmd_daemon ;;
	*) printf 'usage: agent-state.sh {working|input|idle|meta <str>|daemon}\n' >&2; exit 2 ;;
esac
