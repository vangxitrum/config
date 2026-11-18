#!/bin/bash
# Configure Dunst as this user's notification daemon, without sudo.
# The binaries come from scripts/i3.sh (~/.local/lib/i3-desktop).
set -euo pipefail

if (( EUID == 0 )); then
  echo "Run this as the user who will run i3." >&2
  exit 1
fi

dunst="$HOME/.local/bin/dunst"
if [[ ! -x "$dunst" ]]; then
  echo "Dunst is not installed; run ./scripts/i3.sh first." >&2
  exit 1
fi

# The session bus reads ~/.local/share/dbus-1/services before the system
# directories, so this entry wins over notify-osd or GNOME's daemon when
# something asks for notifications before i3 has started Dunst.
services="${XDG_DATA_HOME:-$HOME/.local/share}/dbus-1/services"
mkdir -p "$services"
cat > "$services/org.freedesktop.Notifications.service" <<EOF
[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=$dunst
EOF
echo "Registered Dunst for org.freedesktop.Notifications in $services."

# The Dunst config is linked by install.sh (config/dunst -> ~/.config/dunst).
mkdir -p "$HOME/.config/scripts"
install -m 755 ./scripts/dunst_handler.sh "$HOME/.config/scripts/dunst_handler.sh"
echo "Dunst is configured."
