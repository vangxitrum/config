#!/bin/bash

# Get list of available IBus engines
engines=($(ibus list-engine | grep -E "(xkb:us::eng|Unikey)" | awk '{print $1}'))

# Get current engine
current=$(ibus engine 2>/dev/null)

# Find current engine index
current_index=-1
for i in "${!engines[@]}"; do
    if [[ "${engines[$i]}" == "$current" ]]; then
        current_index=$i
        break
    fi
done

# Switch to next engine
if [ $current_index -eq -1 ]; then
    # If current engine not found, switch to first engine
    next_engine="${engines[0]}"
else
    # Switch to next engine (cycle back to first if at end)
    next_index=$(( (current_index + 1) % ${#engines[@]} ))
    next_engine="${engines[$next_index]}"
fi

# Switch to the next engine
ibus engine "$next_engine"
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
