#!/usr/bin/env bash
# Claude Code status line — mirrors Pure/p10k style:
#   dir  git-repo  model  context%
# Colors are rendered dimmed by the terminal, so we use bold+color for contrast.

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
repo=$(echo "$input" | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end')
branch=$(echo "$input" | jq -r '.worktree.branch // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Push a compact context-usage readout to this window's tmux tab indicator, so a
# running-agent tab shows how full the context is. Best-effort; no-op outside tmux.
if [ -n "${TMUX:-}" ] && [ -x "$HOME/work/config/scripts/agent-state.sh" ]; then
    meta=""
    if [ -n "$remaining" ]; then
        rem=$(printf '%.0f' "$remaining")
        meta="ctx $(( 100 - rem ))%"
    fi
    "$HOME/work/config/scripts/agent-state.sh" meta "$meta" >/dev/null 2>&1 || true
fi

# Shorten home prefix
home="$HOME"
short_cwd="${cwd/#$home/~}"

# Build output pieces
parts=()

# Directory (blue)
[ -n "$short_cwd" ] && parts+=("$(printf '\033[34m%s\033[0m' "$short_cwd")")

# Git repo + branch (grey)
if [ -n "$repo" ]; then
    if [ -n "$branch" ]; then
        parts+=("$(printf '\033[90m%s:%s\033[0m' "$repo" "$branch")")
    else
        parts+=("$(printf '\033[90m%s\033[0m' "$repo")")
    fi
fi

# Model (magenta)
[ -n "$model" ] && parts+=("$(printf '\033[35m%s\033[0m' "$model")")

# Context remaining (yellow when low, grey otherwise)
if [ -n "$remaining" ]; then
    pct=$(printf '%.0f' "$remaining")
    if [ "$pct" -le 20 ]; then
        parts+=("$(printf '\033[33mctx:%s%%\033[0m' "$pct")")
    else
        parts+=("$(printf '\033[90mctx:%s%%\033[0m' "$pct")")
    fi
fi

# Join with spaces
printf '%s' "${parts[0]}"
for part in "${parts[@]:1}"; do
    printf ' %s' "$part"
done
printf '\n'
