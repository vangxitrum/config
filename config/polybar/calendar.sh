#!/bin/sh
# Toggle a calendar popup from the Polybar date module.
#
# polycal.py is preferred: it shows the Chinese lunar date, marks today, and
# loads the same gtk.css as the bar. gsimplecal is kept as a fallback (it can
# do neither), then yad, then zenity, then cal(1).

THEME_DIR="$HOME/.config/polybar/gsimplecal-theme"
POLYCAL="$HOME/.config/polybar/polycal.py"
STAMP="/tmp/.calendar-click.stamp"

# polybar delivers this click twice, ~40ms apart; without a guard the second
# invocation immediately toggles the window back closed.
now=$(date +%s%N)
if [ -f "$STAMP" ]; then
	last=$(cat "$STAMP" 2>/dev/null) || last=0
	[ -z "$last" ] && last=0
	if [ $(( (now - last) / 1000000 )) -lt 400 ]; then
		exit 0
	fi
fi
printf '%s' "$now" > "$STAMP"

place() {
	# i3-msg resolves the socket from the X root atom; a stale inherited
	# I3SOCK would point at a dead session
	(unset I3SOCK; "$HOME/.config/polybar/calendar-place.py") &
}

# polycal positions itself (it can read the pointer via GDK, which the
# external placer cannot); only the gsimplecal fallback needs place().
if [ -x "$POLYCAL" ] && python3 -c 'import gi' 2>/dev/null; then
	exec "$POLYCAL"
fi

if command -v gsimplecal >/dev/null 2>&1; then
	if pgrep -x gsimplecal >/dev/null 2>&1; then
		XDG_CONFIG_HOME="$THEME_DIR" exec gsimplecal
	fi
	place
	XDG_CONFIG_HOME="$THEME_DIR" exec gsimplecal
fi

if command -v yad >/dev/null 2>&1; then
	pkill -f '^yad --calendar' && exit 0
	exec yad --calendar --undecorated --no-buttons \
		--close-on-unfocus --width=260 --height=220
fi

if command -v zenity >/dev/null 2>&1; then
	pkill -f '^zenity --calendar' && exit 0
	exec zenity --calendar --title="Calendar" --text=""
fi

pkill -f '^xmessage' && exit 0
exec xmessage -center "$(cal -3)"
