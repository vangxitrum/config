#!/bin/bash

# Get current IBus engine
current=$(ibus engine 2>/dev/null)

# Handle case when ibus is not running or no engine set
if [ -z "$current" ] || [ "$current" = "No engine is set." ]; then
    # Fallback to xkb layout
    layout=$(setxkbmap -query | grep layout | awk '{print $2}')
    case $layout in
        "us") echo "EN" ;;
        "Unikey") echo "VI" ;;
        *) echo "XKB" ;;
    esac
else
    # Map IBus engines to display names
    case $current in
        "xkb:us::eng"|"xkb:us:altgr-intl:eng") echo "EN" ;;
        "Unikey") echo "VI" ;;
        *) echo "??" ;;
    esac
fi
