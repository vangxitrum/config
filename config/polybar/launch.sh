#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
# polybar-msg cmd quit
# # Otherwise you can use the nuclear option:
# # killall -q polybar
#
# # Launch bar1 and bar2
# echo "---" | tee -a /tmp/polybar1.log
# polybar bar 2>&1 -c ~/.config/polybar/config.ini | tee -a /tmp/polybar1.log & disown
#
# echo "Bars launched..."
# if type "xrandr"; then
#   for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
#     MONITOR=$m polybar --reload bar -c ~/.config/polybar/config.ini | tee -a /tmp/polibar1.log & disown &
#   done
# else
#   polybar --reload example &
# fi
#!/bin/bash
(
  flock 200

  killall -q polybar

  while pgrep -u $UID -x polybar > /dev/null; do sleep 0.5; done

  outputs=$(xrandr --query | grep " connected" | cut -d" " -f1)
  tray_output=eDP1

  for m in $outputs; do
    if [[ $m == "HDMI1" ]]; then
        tray_output=$m
    fi
  done

  for m in $outputs; do
    export MONITOR=$m
    export TRAY_POSITION=none
    if [[ $m == $tray_output ]]; then
      TRAY_POSITION=right
    fi

    polybar --reload bar -c ~/.config/polybar/config.ini </dev/null >/var/tmp/polybar-$m.log 2>&1 200>&- &
    disown
  done
) 200>/var/tmp/polybar-launch.lock
