#!/bin/bash

# Use the IM name as the source of truth (more reliable than state code).
# Fallback to state if fcitx5-remote -n unavailable.
# fcitx5-remote state codes: 0=fcitx not running, 1=passthrough (keyboard
# layout), 2=intercepting (real IM like bamboo).

name=$(fcitx5-remote -n 2>/dev/null)
if [ -n "$name" ]; then
    case $name in
        *bamboo*|*unikey*|*vi*) echo "VI" ;;
        *) echo "EN" ;;
    esac
else
    case $(fcitx5-remote) in
        2) echo "VI" ;;
        *) echo "EN" ;;
    esac
fi
