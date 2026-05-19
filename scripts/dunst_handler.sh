#!/bin/bash

# Dunst handler script
# This script runs whenever a notification is received.
# It attempts to focus the application window or launch it if not running.

# Arguments passed by Dunst:
# appname, summary, body, icon, urgency
appname="$1"
summary="$2"
body="$3"
icon="$4"
urgency="$5"

# Skip certain apps that shouldn't trigger a focus switch
# Add apps to this list to prevent annoying focus jumps
case "$appname" in
    "Volume"|"Brightness"|"NetworkManager"|"Battery")
        exit 0
        ;;
esac

# 1. Try to focus an existing window in i3
# We search for class, instance, or title matching the appname (case-insensitive)
# Using i3-msg to query and focus
if i3-msg "[class=\"(?i)$appname\"] focus" || i3-msg "[instance=\"(?i)$appname\"] focus" || i3-msg "[title=\"(?i)$appname\"] focus"; then
    exit 0
fi

# 2. If no window found, try to find a matching .desktop file to launch
# Common locations for desktop files
search_dirs=("/usr/share/applications" "$HOME/.local/share/applications" "/var/lib/flatpak/exports/share/applications")

for dir in "${search_dirs[@]}"; do
    if [ -d "$dir" ]; then
        # Search for Name=appname or Exec=appname in .desktop files
        desktop_file=$(grep -ilE "^(Name|Exec)=.*$appname" "$dir"/*.desktop 2>/dev/null | head -n 1)
        
        if [ -n "$desktop_file" ]; then
            # Extract Exec command, removing %u, %f, etc.
            exec_cmd=$(grep "^Exec=" "$desktop_file" | head -n 1 | cut -d'=' -f2 | sed 's/ %.*//')
            if [ -n "$exec_cmd" ]; then
                # Run the command in the background
                $exec_cmd &
                exit 0
            fi
        fi
    fi
done

# 3. Last resort: try to run the appname as a command directly
if command -v "$appname" &>/dev/null; then
    "$appname" &
fi
