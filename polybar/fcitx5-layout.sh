#!/bin/bash

# Get current Fcitx5 input method using fcitx5-remote
# fcitx5-remote returns:
# 0 for inactive (usually the first IM, e.g., English)
# 1 for active (usually the second IM, e.g., Unikey)
# 2 for inactive (redundant but possible)

state=$(fcitx5-remote)

case $state in
    1)
        echo "VI"
        ;;
    2|0)
        echo "EN"
        ;;
    *)
        # Fallback to checking the current IM name if fcitx5-remote -n is available
        name=$(fcitx5-remote -n 2>/dev/null)
        case $name in
            *unikey*|*vi*) echo "VI" ;;
            *) echo "EN" ;;
        esac
        ;;
esac
