#!/usr/bin/env python3
"""Clamp the gsimplecal popup inside the output it opened on.

gsimplecal's mainwindow_position=mouse puts the window's LEFT edge at the
cursor, so clicking a clock at the right edge of a bar pushes the window onto
the neighbouring monitor. This nudges it back inside, anchored just below the
bar (the i3 workspace rect already excludes dock/bar area).
"""
import json
import subprocess
import sys
import time

MARGIN = 4
# ordered by preference: a stale window of the other kind must not win
CLASSES = ("polycal", "gsimplecal")


def i3(*args):
    out = subprocess.run(["i3-msg", *args], capture_output=True, text=True)
    if out.returncode != 0 or not out.stdout.strip():
        return None
    return json.loads(out.stdout)


def find_window(tree):
    found = {}

    def walk(n):
        wp = n.get("window_properties") or {}
        cls = (wp.get("class") or "").lower()
        if cls in CLASSES:
            found.setdefault(cls, n)
        for key in ("nodes", "floating_nodes"):
            for c in n.get(key) or []:
                walk(c)

    walk(tree)
    for cls in CLASSES:
        if cls in found:
            return found[cls]
    return None


def main():
    # the window is mapped asynchronously; wait briefly for it
    win = None
    # polycal (python + GTK) can take well over a second to map; gsimplecal
    # is near-instant. Poll generously rather than silently giving up.
    for _ in range(160):
        tree = i3("-t", "get_tree")
        if tree:
            win = find_window(tree)
            if win:
                break
        time.sleep(0.025)
    if not win:
        return 1

    r = win["rect"]
    workspaces = i3("-t", "get_workspaces") or []
    visible = [w for w in workspaces if w.get("visible")]
    if not visible:
        return 1

    # the workspace whose rect contains the window's top-left corner,
    # else the one whose horizontal span covers it, else the first
    def contains(w):
        a = w["rect"]
        return a["x"] <= r["x"] < a["x"] + a["width"]

    ws = next((w for w in visible if contains(w)), visible[0])
    a = ws["rect"]

    x = min(r["x"], a["x"] + a["width"] - r["width"] - MARGIN)
    x = max(x, a["x"] + MARGIN)
    y = a["y"] + MARGIN

    if (x, y) != (r["x"], r["y"]):
        cls = (win['window_properties'] or {}).get('class')
        i3("-t", "command", f'[class="{cls}"] move position {x} {y}')
    return 0


if __name__ == "__main__":
    sys.exit(main())
