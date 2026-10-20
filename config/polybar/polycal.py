#!/usr/bin/env python3
"""Calendar popup for the polybar clock, with the lunar date underneath.

Replaces gsimplecal, which cannot show a lunar date and whose mark_today
styling is invisible under a custom stylesheet. Lunar conversion uses ICU's
Chinese calendar, which handles leap months correctly.
"""
import datetime
import functools
import json
import os
import signal
import subprocess
import sys
import time

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, GLib, Gtk  # noqa: E402

PIDFILE = "/tmp/.polycal.pid"
MARGIN = 4
# Set in markup, not CSS - see day_detail() for why.
DETAIL_COLOUR = "#a89984"        # readable grey on the dark bar background
DETAIL_START_COLOUR = "#d79921"  # gold, marks the first day of a lunar month
CSS = os.path.expanduser("~/.config/polybar/gsimplecal-theme/gtk-3.0/gtk.css")


@functools.lru_cache(maxsize=512)
def lunar_fields(y, m, d):
    """(lunar_day, lunar_month, lunar_year, is_leap), or None without ICU."""
    try:
        import icu
    except ImportError:
        return None
    loc = icu.Locale("zh_CN@calendar=chinese")
    # PyICU's UDate is in SECONDS. Noon avoids DST/timezone day-flips.
    secs = time.mktime(datetime.datetime(y, m, d, 12, 0, 0).timetuple())
    cal = icu.Calendar.createInstance(loc)
    cal.setTime(secs)
    # ICU exposes no IS_LEAP_MONTH constant here; the localized month name
    # carries the leap marker instead. 'r' is the related Gregorian year,
    # which correctly stays on the old year for dates before lunar new year.
    name = icu.SimpleDateFormat("MMM", loc).format(secs)
    year = icu.SimpleDateFormat("r", loc).format(secs)
    return (
        cal.get(icu.Calendar.DATE),
        cal.get(icu.Calendar.MONTH) + 1,
        year,
        "闰" in name or "閏" in name,
    )


def lunar(d):
    """Full lunar date as dd/mm/yyyy. Leap months get a + after the month."""
    f = lunar_fields(d.year, d.month, d.day)
    if not f:
        return ""
    day, month, year, leap = f
    return f"{day:02d}/{month:02d}{'+' if leap else ''}/{year}"


class Popup(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_title("Calendar")
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_resizable(False)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(box)

        self.cal = Gtk.Calendar()
        self.cal.set_detail_func(self.day_detail)
        self.cal.set_detail_width_chars(4)
        self.cal.set_detail_height_rows(1)
        box.pack_start(self.cal, True, True, 0)

        self.caption = Gtk.Label()
        self.caption.set_name("lunar")
        box.pack_start(self.caption, False, False, 0)

        self.cal.connect("day-selected", self.refresh)
        self.cal.connect("month-changed", self.refresh)
        self.connect("key-press-event", self.on_key)
        self.connect("destroy", lambda *_: self.quit())

        # No close-on-focus-out: i3 defaults to focus_follows_mouse, and the
        # popup is placed under the bar rather than under the cursor, so it
        # loses focus the instant it opens. Dismiss with Escape, or by
        # clicking the clock again.
        self.refresh(self.cal)

    def day_detail(self, _cal, year, month, day):
        """Small lunar number under each day; 'd/m' on a lunar month start.

        The colour is set in markup rather than CSS: GtkCalendar renders the
        detail with the cell's own style context, so days outside the current
        month would inherit the dimmed colour and become unreadable.
        """
        f = lunar_fields(year, month + 1, day)
        if not f:
            return None
        lday, lmonth, _lyear, leap = f
        if lday == 1:
            text = f"{lday}/{lmonth}{'+' if leap else ''}"
            colour = DETAIL_START_COLOUR
        else:
            text = str(lday)
            colour = DETAIL_COLOUR
        return f"<span size='x-small' foreground='{colour}'>{text}</span>"

    def selected(self):
        year, month, day = self.cal.get_date()
        try:
            return datetime.date(year, month + 1, day)
        except ValueError:
            return datetime.date.today()

    def refresh(self, _cal):
        # bold today, but only while its own month is on screen
        today = datetime.date.today()
        self.cal.clear_marks()
        year, month, _ = self.cal.get_date()
        if (year, month + 1) == (today.year, today.month):
            self.cal.mark_day(today.day)
        self.caption.set_text(lunar(self.selected()))

    def place_under_clock(self):
        """Right-align under the bar clock, on the monitor holding the pointer.

        The pointer identifies which bar was clicked. The usable rect comes
        from i3's visible workspace, not GDK's workarea: polybar publishes no
        _NET_WORKAREA strut here, so GDK reports the full monitor and the
        popup would land on top of the bar.
        """
        display = Gdk.Display.get_default()
        _s, px, py = display.get_default_seat().get_pointer().get_position()
        width, height = self.get_size()

        rect = None
        try:
            env = dict(os.environ)
            env.pop("I3SOCK", None)  # a stale value points at a dead session
            out = subprocess.run(
                ["i3-msg", "-t", "get_workspaces"],
                capture_output=True, text=True, env=env, timeout=2,
            )
            for ws in json.loads(out.stdout):
                if not ws.get("visible"):
                    continue
                r = ws["rect"]
                if r["x"] <= px < r["x"] + r["width"]:
                    rect = r
                    break
        except Exception:
            rect = None

        if rect is None:  # fall back to the monitor, minus a guessed bar
            monitor = display.get_monitor_at_point(px, py)
            if monitor is None:
                return
            geo = monitor.get_geometry()
            rect = {"x": geo.x, "y": geo.y + 42,
                    "width": geo.width, "height": geo.height - 42}

        x = rect["x"] + rect["width"] - width - MARGIN
        y = rect["y"] + MARGIN
        self.move(x, y)
        if os.environ.get("POLYCAL_DEBUG"):
            print(f"pointer=({px},{py}) size=({width},{height}) rect={rect} "
                  f"-> move({x},{y}) actual={self.get_position()}",
                  file=sys.stderr)

    def on_key(self, _w, event):
        if event.keyval == Gdk.KEY_Escape:
            self.quit()
        return False

    def quit(self):
        try:
            os.unlink(PIDFILE)
        except OSError:
            pass
        Gtk.main_quit()


def running_pid():
    try:
        with open(PIDFILE) as fh:
            pid = int(fh.read().strip())
        os.kill(pid, 0)
    except (OSError, ValueError):
        return None
    return pid


def main():
    pid = running_pid()
    if pid:
        os.kill(pid, signal.SIGTERM)  # second click closes it
        return 0

    GLib.set_prgname("polycal")
    Gdk.set_program_class("Polycal")
    if os.path.exists(CSS):
        provider = Gtk.CssProvider()
        provider.load_from_path(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_USER,
        )

    win = Popup()
    with open(PIDFILE, "w") as fh:
        fh.write(str(os.getpid()))
    signal.signal(signal.SIGTERM, lambda *_: win.quit())
    win.show_all()
    win.place_under_clock()
    Gtk.main()
    return 0


if __name__ == "__main__":
    sys.exit(main())
