#!/usr/bin/env python3
"""Waybar weather pill + hourly popup (Brooklyn 11206, via open-meteo).

  weather.py          pill text; waybar runs it every 5s and the unit
                      alternates C/F from one cached fetch
  weather.py popup    today's hour-by-hour card (pill on-click)

One request (current + hourly + sunrise/sunset) at most every 5 minutes,
cached in $XDG_RUNTIME_DIR; both modes read the same cache, so the pill
and the popup never disagree. Coordinates, not a ZIP lookup: wttr.in
geocoded bare "11206" to Algeciras, Spain.
"""

import json
import os
import sys
import time
import urllib.request

LAT, LON = 40.7019, -73.9424  # ZIP 11206
PLACE = "Brooklyn"
MAX_AGE = 300    # seconds a fetch stays fresh
RETRY = 60       # seconds between attempts while fetches fail

RUNTIME = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
CACHE = os.path.join(RUNTIME, "waybar_weather.json")
TRIED = CACHE + ".tried"
URL = (
    "https://api.open-meteo.com/v1/forecast"
    f"?latitude={LAT}&longitude={LON}"
    "&current=temperature_2m,weather_code,is_day"
    "&hourly=temperature_2m,precipitation_probability,weather_code,is_day"
    "&daily=sunrise,sunset,temperature_2m_max,temperature_2m_min"
    "&timezone=auto&forecast_days=1"
)


def age(path):
    try:
        return time.time() - os.stat(path).st_mtime
    except OSError:
        return float("inf")


def load():
    """Cached forecast, refreshed when stale. A failed fetch keeps serving
    the old data (and backs off) rather than blanking the pill."""
    if age(CACHE) > MAX_AGE and age(TRIED) > RETRY:
        try:
            open(TRIED, "w").close()
            with urllib.request.urlopen(URL, timeout=5) as r:
                raw = r.read()
            json.loads(raw)["current"]["temperature_2m"]  # sanity
            with open(CACHE + ".tmp", "wb") as f:
                f.write(raw)
            os.replace(CACHE + ".tmp", CACHE)
        except (OSError, ValueError, KeyError):
            pass
    try:
        with open(CACHE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def icon(code, is_day=1):
    """WMO weather code -> emoji."""
    if code == 0:
        return "☀️" if is_day else "🌙"
    if code == 1:
        return "🌤️" if is_day else "🌙"
    if code == 2:
        return "⛅" if is_day else "☁️"
    if code == 3:
        return "☁️"
    if code in (45, 48):
        return "🌫️"
    if code in (51, 53, 55, 80):
        return "🌦️"
    if code in (56, 57, 61, 63, 65, 66, 67, 81, 82):
        return "🌧️"
    if code in (71, 73, 75, 77):
        return "❄️"
    if code in (85, 86):
        return "🌨️"
    if code in (95, 96, 99):
        return "⛈️"
    return "☁️"


def f_of(c):
    return c * 9 / 5 + 32


def pill():
    d = load()
    if not d:
        return
    cur = d["current"]
    c = cur["temperature_2m"]
    temp = f"{round(f_of(c))}°F" if int(time.time() / 5) % 2 else f"{round(c)}°C"
    print(f"{icon(cur['weather_code'], cur['is_day'])} {temp}")


# ---------------------------------------------------------------- popup

def build_card(d, now=None):
    """The hourly card as a Gtk widget (no window), so it can be rendered
    off-screen too."""
    import gi

    gi.require_version("Gtk", "3.0")
    from gi.repository import GLib, Gtk

    esc = GLib.markup_escape_text
    now = now or time.localtime()
    cur, hourly, daily = d["current"], d["hourly"], d["daily"]
    temps = hourly["temperature_2m"]
    lo, hi = min(temps), max(temps)

    def label(markup, xalign=0.0, width=None, name=None):
        l = Gtk.Label()
        l.set_markup(markup)
        l.set_xalign(xalign)
        if width:
            l.set_size_request(width, -1)
        if name:
            l.set_name(name)
        return l

    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
    for m in ("top", "bottom", "start", "end"):
        getattr(box, f"set_margin_{m}")(20)

    header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=24)
    header.pack_start(label(f"<b>{esc(PLACE)}</b>", name="title"), False, False, 0)
    header.pack_start(
        label(esc(time.strftime("%A, %B %-d", now)), xalign=1, name="title"),
        True, True, 0,
    )
    box.add(header)

    c = cur["temperature_2m"]
    big = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
    big.set_margin_top(10)
    big.add(label(f'<span size="30720">{icon(cur["weather_code"], cur["is_day"])}</span>'))
    big.add(label(
        f'<span size="30720" weight="bold">{round(f_of(c))}°F</span>'
        f'<span size="16384" foreground="#7f849c">  {round(c)}°C</span>'
    ))
    box.add(big)

    tmax, tmin = daily["temperature_2m_max"][0], daily["temperature_2m_min"][0]
    rise, sset = daily["sunrise"][0][11:16], daily["sunset"][0][11:16]
    summary = label(
        f'<span foreground="#7f849c">'
        f"↑ {round(f_of(tmax))}°  ↓ {round(f_of(tmin))}°"
        f"     🌅 {rise}   🌇 {sset}</span>"
    )
    summary.set_margin_top(4)
    summary.set_margin_bottom(12)
    box.add(summary)

    today = time.strftime("%Y-%m-%d", now)
    for i, stamp in enumerate(hourly["time"]):
        if not stamp.startswith(today):
            continue
        hour = int(stamp[11:13])
        t = temps[i]
        rain = hourly["precipitation_probability"][i] or 0
        frac = (t - lo) / (hi - lo) if hi > lo else 0.5

        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        ctx = row.get_style_context()
        ctx.add_class("row")
        if hour < now.tm_hour:
            ctx.add_class("past")
        elif hour == now.tm_hour:
            ctx.add_class("now")

        row.add(label(f"{hour:02d}:00", width=46))
        row.add(label(icon(hourly["weather_code"][i], hourly["is_day"][i]), xalign=0.5, width=26))
        row.add(label(f"{round(f_of(t))}°F", xalign=1, width=44))
        row.add(label(f'<span foreground="#7f849c">{round(t)}°C</span>', xalign=1, width=40))

        bar = Gtk.DrawingArea()
        bar.set_size_request(130, 8)
        bar.set_valign(Gtk.Align.CENTER)
        bar.connect("draw", draw_bar, frac)
        row.add(bar)

        row.add(label(
            f'<span foreground="#89b4fa">💧{rain}%</span>' if rain >= 10 else "",
            xalign=1, width=58,
        ))
        box.add(row)

    return box


def draw_bar(area, cr, frac):
    """Rounded bar, length and colour by where the hour sits between the
    day's low (sky) and high (peach)."""
    import math

    w, h = area.get_allocated_width(), area.get_allocated_height()
    cold, warm = (0x89, 0xDC, 0xEB), (0xFA, 0xB3, 0x87)
    r, g, b = (
        (cold[k] + (warm[k] - cold[k]) * frac) / 255 for k in range(3)
    )
    length = h + (w - h) * frac
    rad = h / 2
    cr.set_source_rgb(r, g, b)
    cr.arc(rad, rad, rad, math.pi / 2, 3 * math.pi / 2)
    cr.arc(length - rad, rad, rad, -math.pi / 2, math.pi / 2)
    cr.close_path()
    cr.fill()


# catppuccin, matching waybar's style.css
CSS = b"""
    window { background-color: transparent; }
    #card { background-color: #1e1e2e; border: 1px solid #313244;
            border-radius: 10px;
            box-shadow: 0 4px 18px rgba(0, 0, 0, 0.55); }
    #card label { color: #cdd6f4;
                  font-family: Roboto, Helvetica, Arial, sans-serif; }
    #title { color: #89dceb; }
    .row { padding: 2px 8px; border-radius: 6px; }
    .row.past { opacity: 0.4; }
    .row.now { background-color: #313244; }
    .row.now label { font-weight: bold; }
"""


def single_instance():
    """A second click on the pill closes the open popup."""
    import signal

    pidfile = os.path.join(RUNTIME, "waybar_weather_popup.pid")
    try:
        old = int(open(pidfile).read())
        with open(f"/proc/{old}/cmdline", "rb") as f:
            if b"weather.py" in f.read():
                os.kill(old, signal.SIGTERM)
                sys.exit(0)
    except (OSError, ValueError):
        pass
    with open(pidfile, "w") as f:
        f.write(str(os.getpid()))


def click_placement():
    """(click x, bar height, monitor w, monitor h) in logical pixels on the
    clicked monitor; the cursor at launch stands in for the pill."""
    import subprocess

    try:
        pos = json.loads(subprocess.check_output(["hyprctl", "cursorpos", "-j"], text=True))
        mons = json.loads(subprocess.check_output(["hyprctl", "monitors", "-j"], text=True))
        for m in mons:
            w, h = m["width"] / m["scale"], m["height"] / m["scale"]
            if m["x"] <= pos["x"] < m["x"] + w and m["y"] <= pos["y"] < m["y"] + h:
                return pos["x"] - m["x"], m["reserved"][1], int(w), int(h)
    except (OSError, subprocess.SubprocessError, ValueError, KeyError):
        pass
    return None


def popup():
    """Fullscreen transparent layer-shell overlay holding the card under
    the pill; a click anywhere else, or Esc, dismisses it (same scheme as
    dailyglot-popup)."""
    single_instance()
    d = load()
    if not d:
        sys.exit(1)

    import gi

    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import Gdk, Gtk, GtkLayerShell

    win = Gtk.Window()
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_namespace(win, "weather-popup")
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
    for edge in (
        GtkLayerShell.Edge.TOP,
        GtkLayerShell.Edge.BOTTOM,
        GtkLayerShell.Edge.LEFT,
        GtkLayerShell.Edge.RIGHT,
    ):
        GtkLayerShell.set_anchor(win, edge, True)
    GtkLayerShell.set_exclusive_zone(win, -1)  # cover waybar too
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.EXCLUSIVE)

    screen = win.get_screen()
    rgba = screen.get_rgba_visual()
    if rgba:
        win.set_visual(rgba)
    css = Gtk.CssProvider()
    css.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_screen(
        screen, css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

    scroller = Gtk.ScrolledWindow()
    scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
    scroller.set_propagate_natural_width(True)
    scroller.set_propagate_natural_height(True)
    scroller.set_max_content_height(800)
    scroller.add(build_card(d))

    card = Gtk.EventBox(name="card", halign=Gtk.Align.CENTER, valign=Gtk.Align.CENTER)
    card.add(scroller)
    card.connect("button-press-event", lambda w, e: True)  # don't fall through

    place = click_placement()
    if place:
        left, bar_h, mon_w, mon_h = place
        card.set_halign(Gtk.Align.START)
        card.set_valign(Gtk.Align.START)
        card.set_margin_top(bar_h + 16)
        card.set_margin_start(left)
        scroller.set_max_content_height(mon_h - bar_h - 60)

        def keep_on_screen(widget, alloc):
            card.set_margin_start(max(8, min(left, mon_w - alloc.width - 8)))

        card.connect("size-allocate", keep_on_screen)

    bg = Gtk.EventBox(visible_window=False)
    bg.connect("button-press-event", lambda w, e: Gtk.main_quit())
    bg.add(card)
    win.add(bg)
    win.connect(
        "key-press-event",
        lambda w, e: Gtk.main_quit() if e.keyval == Gdk.KEY_Escape else None,
    )
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()


if __name__ == "__main__":
    popup() if sys.argv[1:] == ["popup"] else pill()
