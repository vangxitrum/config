#!/usr/bin/env bash
dunstctl close
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/tmux-jump/active"
