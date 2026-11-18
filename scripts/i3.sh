#!/bin/bash
# Install i3 and the desktop tools it launches from Ubuntu packages, under
# ~/.local, without sudo and without registering anything with dpkg.
set -euo pipefail

if (( EUID == 0 )); then
  echo "Run this installer as the user who will run i3." >&2
  exit 1
fi

packages=()
commands=()
# want <package> <command>... — add a package and the commands to link from it.
want() {
  packages+=("$1")
  shift
  commands+=("$@")
}
# maybe <package> <command>... — same, but skip packages this release lacks.
maybe() {
  if apt-cache policy "$1" 2>/dev/null | grep -q 'Candidate: [^(]'; then
    want "$@"
  else
    echo "$1 is unavailable in the configured APT repositories; skipping it." >&2
  fi
}

want i3-wm i3 i3-msg i3-nagbar i3-config-wizard i3-sensible-terminal i3bar
want i3status i3status
want i3lock i3lock
want suckless-tools dmenu dmenu_run dmenu_path stest
want dex dex
want xss-lock xss-lock
want polybar polybar polybar-msg
want dunst dunst dunstctl dunstify
want picom picom
want flameshot flameshot
maybe nitrogen nitrogen
# Input method (Vietnamese Telex). Apps reach it through the IBus modules
# already on the system (GTK, Qt, kitty) or XIM; see i3-session below.
want fcitx5 fcitx5 fcitx5-remote
want fcitx5-unikey
# PyICU: Chinese/lunar dates in the Polybar calendar (polybar/polycal.py).
want python3-icu
# Starting X from a text console: xinit, plus the keyboard/mouse driver that
# Xorg loads from the bundle (see start-i3 below). Xorg itself stays system.
want xinit xinit
want xserver-xorg-input-libinput
scripts=(start-i3)
# notify-send ships with most desktops; bring our own only when it is missing.
if ! command -v notify-send >/dev/null || [[ $(command -v notify-send) == "$HOME/.local/bin/notify-send" ]]; then
  want libnotify-bin notify-send
fi

prefix="$HOME/.local/lib/i3-desktop"
bin="$HOME/.local/bin"
launcher="$prefix/launch"
for command_name in "${commands[@]}"; do
  target="$bin/$command_name"
  if [[ -e "$target" || -L "$target" ]] && [[ $(readlink "$target" || true) != "$launcher" ]]; then
    echo "Another installation already owns $target." >&2
    exit 1
  fi
done
for script in "${scripts[@]}"; do
  target="$bin/$script"
  if [[ -e "$target" || -L "$target" ]] && [[ $(readlink "$target" || true) != "$prefix/$script" ]]; then
    echo "Another installation already owns $target." >&2
    exit 1
  fi
done
if [[ ! -x /usr/lib/xorg/Xorg ]]; then
  echo "Note: Xorg is not installed (sudo apt-get install xserver-xorg-core); start-i3 needs it." >&2
fi

# Resolve dependencies against the current system without changing APT state.
# Only packages missing from the system are extracted; upgrades of installed
# libraries are left to APT so the bundle never shadows a system library.
plan=$(LC_ALL=C apt-get --simulate --no-remove --no-install-recommends install "${packages[@]}")
mapfile -t download < <(
  { printf '%s\n' "${packages[@]}"; awk '$1 == "Inst" && $3 !~ /^\[/ { print $2 }' <<< "$plan"; } | sort -u
)

mkdir -p "$HOME/.local/lib" "$bin"
stage=$(mktemp -d "$HOME/.local/lib/.i3-desktop.XXXXXXXX")
trap 'find "$stage" -depth -delete' EXIT
mkdir "$stage/packages" "$stage/root"
(
  cd "$stage/packages"
  apt-get download "${download[@]}"
  for package in ./*.deb; do
    dpkg-deb --extract "$package" "$stage/root"
  done
)

cat > "$stage/root/launch" <<'LAUNCHER'
#!/bin/bash
root="$HOME/.local/lib/i3-desktop"
name=${0##*/}
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
for directory in "$root"/usr/lib/*-linux-gnu "$root"/lib/*-linux-gnu; do
  if [[ -d "$directory" && ":${LD_LIBRARY_PATH:-}:" != *":$directory:"* ]]; then
    export LD_LIBRARY_PATH="$directory${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  fi
done
# Qt plugins only for the Qt tool, so they do not leak into everything i3 starts.
if [[ $name == flameshot ]]; then
  for directory in "$root"/usr/lib/*-linux-gnu/qt6/plugins; do
    [[ -d "$directory" ]] && export QT_PLUGIN_PATH="$directory${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
  done
fi
# Fcitx5 looks for addons and their data under /usr unless told otherwise.
if [[ $name == fcitx5* ]]; then
  for directory in "$root"/usr/lib/*-linux-gnu/fcitx5; do
    export FCITX_ADDON_DIRS="$directory"
  done
  export FCITX_DATA_DIRS="$root/usr/share/fcitx5"
fi
exec "$root/usr/bin/$name" "$@"
LAUNCHER
chmod 755 "$stage/root/launch"

# start-i3: run from a text console (Ctrl+Alt+F3). Starts rootless Xorg on
# this console through logind, with the bundled input driver and its config.
cat > "$stage/root/start-i3" <<'START'
#!/bin/bash
set -euo pipefail
root="$HOME/.local/lib/i3-desktop"
if [[ -z ${XDG_VTNR:-} || -n ${DISPLAY:-}${WAYLAND_DISPLAY:-} ]]; then
  echo "Run start-i3 after logging in on a text console (Ctrl+Alt+F3)." >&2
  exit 1
fi
display=0
while [[ -e /tmp/.X11-unix/X$display || -e /tmp/.X$display-lock ]]; do
  display=$((display + 1))
done
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
touch "$XAUTHORITY"
xauth -q add ":$display" . "$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
exec "$HOME/.local/bin/xinit" "$root/i3-session" -- /usr/lib/xorg/Xorg ":$display" \
  "vt$XDG_VTNR" -keeptty -nolisten tcp -auth "$XAUTHORITY" \
  -configdir "$root/usr/share/X11/xorg.conf.d" \
  -logfile "${XDG_STATE_HOME:-$HOME/.local/state}/Xorg.$display.log"
START

# i3-session: the X client. Sets the input-method variables for everything i3
# starts (fcitx5 answers as IBus, the module GTK, Qt and kitty already have),
# and passes them to D-Bus-started services (Dunst) along with the display.
cat > "$stage/root/i3-session" <<'SESSION'
#!/bin/bash
export XDG_CURRENT_DESKTOP=i3 XDG_SESSION_TYPE=x11
export GTK_IM_MODULE=ibus QT_IM_MODULE=ibus GLFW_IM_MODULE=ibus XMODIFIERS=@im=fcitx
if command -v dbus-update-activation-environment >/dev/null; then
  dbus-update-activation-environment --systemd DISPLAY XAUTHORITY \
    GTK_IM_MODULE QT_IM_MODULE GLFW_IM_MODULE XMODIFIERS
fi
exec "$HOME/.local/bin/i3"
SESSION
chmod 755 "$stage/root/start-i3" "$stage/root/i3-session"

# Module path for the bundled input driver. A Files section (not -modulepath)
# keeps the paths that drivers such as NVIDIA's add in system OutputClass
# sections; Xorg drops those when -modulepath is on the command line.
cat > "$stage/root/usr/share/X11/xorg.conf.d/00-i3-desktop.conf" <<FILES
Section "Files"
    ModulePath "$prefix/usr/lib/xorg/modules"
    ModulePath "/usr/lib/xorg/modules"
EndSection
FILES

for command_name in "${commands[@]}"; do
  if [[ ! -x "$stage/root/usr/bin/$command_name" ]]; then
    echo "Missing $command_name in the downloaded packages." >&2
    exit 1
  fi
done

if [[ -e "$prefix" ]]; then
  mv -T "$prefix" "$stage/previous"
fi
if ! mv -T "$stage/root" "$prefix"; then
  if [[ -d "$stage/previous" ]]; then
    mv -T "$stage/previous" "$prefix"
  fi
  exit 1
fi
for command_name in "${commands[@]}"; do
  ln -sfn "$launcher" "$bin/$command_name"
done
ln -sfn "$prefix/start-i3" "$bin/start-i3"
# Python modules from the bundle (PyICU) for the system python3, via a .pth
# file in the user site directory.
site=$(python3 -c 'import site; print(site.getusersitepackages())')
mkdir -p "$site"
printf '%s\n' "$prefix/usr/lib/python3/dist-packages" > "$site/i3-desktop.pth"
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}"

# Report binaries whose libraries could not be resolved.
missing=0
libraries=$(printf '%s:' "$prefix"/usr/lib/*-linux-gnu "$prefix"/lib/*-linux-gnu)
for command_name in "${commands[@]}"; do
  file="$prefix/usr/bin/$command_name"
  [[ $(head -c4 "$file" | od -An -c | tr -d ' ') == 177ELF ]] || continue
  if unresolved=$(LD_LIBRARY_PATH="$libraries" ldd "$file" 2>&1 | grep 'not found'); then
    echo "$command_name: unresolved libraries:" >&2
    echo "$unresolved" >&2
    missing=1
  fi
done

echo "Installed i3 and desktop helpers under $HOME/.local."
(( missing == 0 )) || echo "Some libraries are missing; install them with APT or report the package." >&2
# i3, Polybar and Dunst configs are linked by install.sh; scripts/dunst.sh
# registers Dunst as the notification daemon.
