-- Hyprland config (Lua). Converted from hyprland.conf on 2026-11-09:
-- Hyprland 0.55+ reads hyprland.lua, 0.57 drops the .conf format.
-- API: /usr/share/hypr/stubs/hl.meta.lua, example /usr/share/hypr/hyprland.lua.
-- Check without restarting: Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
-- hyprctl changed with it: `hyprctl dispatch` takes Lua (hl.dsp.*, e.g.
-- hyprctl dispatch 'hl.dsp.exec_cmd("foo")'), `hyprctl keyword` is gone
-- (use `hyprctl eval`). Scripts: see hl_dispatch in scripts/scratchpad_toggle.sh.


------------------
---- MONITORS ----
------------------

hl.monitor({ output = "",      mode = "preferred", position = "auto",       scale = "auto" })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0",        scale = 1 })
-- External monitor by description, not connector: it is DP-2 on the back
-- USB4 port and DP-1 on the left USB-C port, and should behave the same on both.
local external = "desc:Samsung Electric Company U32R59x HNMNA02466"
hl.monitor({ output = external, mode = "preferred", position = "2000x-2160", scale = 1 })

-- Laptop panel: workspaces 1-4 (master on the left); external: 5-9 (centered).
for i = 1, 4 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1", layout_opts = { orientation = "left" } })
end
for i = 5, 9 do
    hl.workspace_rule({ workspace = tostring(i), monitor = external, layout_opts = { orientation = "center" } })
end


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "alacritty"
local fileManager = "dolphin"
local menu        = "wofi --show drun"
local scripts     = "~/.config/hypr/scripts"


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("keyd-application-mapper -d")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("ydotoold")
    hl.exec_cmd(scripts .. "/scratchpad_unfocus_watch.sh")
    hl.exec_cmd("hypridle")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_THEME",    "phinger-cursors")
hl.env("XCURSOR_SIZE",     "48")
hl.env("HYPRCURSOR_THEME", "phinger-cursors")
hl.env("HYPRCURSOR_SIZE",  "48")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in     = 3,
        gaps_out    = 10,
        border_size = 4,
        col = {
            active_border   = "rgba(ff0000ee)",
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "master",
    },

    decoration = {
        rounding         = 10,
        rounding_power   = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = true, range = 4, render_power = 3, color = 0xee1a1a1a },
        blur   = { enabled = true, size = 3, passes = 1, vibrancy = 0.1696 },
    },

    animations = { enabled = true },

    dwindle = {
        preserve_split      = true,
        default_split_ratio = 1.35,
    },

    master = {
        new_status           = "slave",
        always_keep_position = true,
    },

    misc = {
        force_default_wallpaper   = -1,
        disable_hyprland_logo     = true,
        on_focus_under_fullscreen = 0,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1} } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1} } })

hl.animation({ leaf = "global",           enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",           enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",          enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",           enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",          enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",             enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",           enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 1.74, bezier = "almostLinear", style = "slide" })
hl.animation({ leaf = "workspacesIn",     enabled = true, speed = 1.01, bezier = "almostLinear", style = "slide" })
hl.animation({ leaf = "workspacesOut",    enabled = true, speed = 1.74, bezier = "almostLinear", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2,    bezier = "quick",        style = "fade" })
hl.animation({ leaf = "zoomFactor",       enabled = true, speed = 7,    bezier = "quick" })


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_options = "compose:ralt",

        repeat_delay = 175,
        repeat_rate  = 55,

        follow_mouse   = 0,
        force_no_accel = false,
        sensitivity    = -0.3,
        scroll_factor  = -1.0,

        touchpad = {
            natural_scroll       = true,
            scroll_factor        = 0.1,
            disable_while_typing = true,
            tap_to_click         = false,
            clickfinger_behavior = true,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.device({
    name          = "uniw0001:00-093a:0255-touchpad",
    sensitivity   = 0.5,
    accel_profile = "adaptive",
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"
local exec    = hl.dsp.exec_cmd

-- Scroll through existing workspaces; move/resize windows by dragging.
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys (work on the lock screen, repeat when held).
hl.bind("XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   exec("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", exec("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioNext",  exec("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  exec("playerctl previous"),   { locked = true })

-- Launchers.
hl.bind("ALT + SPACE",       exec([[env BEMENU_BACKEND=wayland /usr/sbin/bemenu-run -b -l 24 -p "Run:"]]))
hl.bind("ALT + T",           exec(terminal))
hl.bind("ALT + B",           exec("firefox"))
hl.bind("SHIFT + ALT + B",   exec("firefox --private-window"))
hl.bind("SUPER + X",         exec([[firefox --new-window "https://docs.google.com/spreadsheets/d/1cDpQtHGIcXykOXMwC3SFtX-clxUGdrCeVk7GuKY3H90/edit?gid=1298980136"]]))
hl.bind("SUPER + r",         exec("hyprctl reload"))
hl.bind("SUPER + L",         exec(scripts .. "/keyboard_backlight.sh"))
hl.bind("SUPER + B",         exec(scripts .. "/bluetooth.sh"))

-- Focus and window movement.
hl.bind("ALT + COMMA",    hl.dsp.focus({ direction = "left" }))
hl.bind("ALT + PERIOD",   hl.dsp.focus({ direction = "right" }))
hl.bind("ALT + u",        hl.dsp.focus({ direction = "down" }))
hl.bind("ALT + i",        hl.dsp.focus({ direction = "up" }))
hl.bind("CTRL + COMMA",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind("CTRL + PERIOD",  hl.dsp.focus({ workspace = "e+1" }))
hl.bind("ALT + KP_Left",  hl.dsp.window.move({ direction = "left" }))
hl.bind("ALT + KP_Down",  hl.dsp.window.move({ direction = "down" }))
hl.bind("ALT + KP_Up",    hl.dsp.window.move({ direction = "up" }))
hl.bind("ALT + KP_Right", hl.dsp.window.move({ direction = "right" }))
hl.bind("ALT + Q",        hl.dsp.window.close())
hl.bind("ALT + F",        hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))

-- Workspaces: ALT + [1-9,0] switches, ALT + SHIFT + [1-9,0] moves the window (0 = 10).
for i = 1, 10 do
    local key = i % 10
    hl.bind("ALT + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind("ALT + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Master layout: CTRL + [2-7] sets the master width, CTRL + M swaps with master.
local mfact = { ["2"] = 0.27, ["3"] = 0.33, ["4"] = 0.38, ["5"] = 0.50, ["6"] = 0.67, ["7"] = 0.73 }
for key, ratio in pairs(mfact) do
    hl.bind("CTRL + " .. key, hl.dsp.layout("mfact exact " .. ratio))
end
hl.bind("CTRL + M", hl.dsp.layout("swapwithmaster"))

-- Mouse clicks via ydotool (left / right).
hl.bind("ALT + C", exec("ydotool click 0xC0"))
hl.bind("ALT + R", exec("ydotool click 0xC1"))

-- Copy the URL in firefox's address bar (no-op outside firefox).
hl.bind("SUPER + CTRL + C", exec(scripts .. "/firefox_copy_url.sh"))

-- Screenshots: selection / active window / focused monitor, each to the
-- clipboard (SUPER) or through swappy with the saved path copied (SUPER + CTRL/SHIFT).
local winGeom = [=[$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')]=]
local monGeom = [=[$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | "\(.x),\(.y) \(.width)x\(.height)"')]=]
local function shot(geom, edit)
    local cmd = 'grim -g "' .. geom .. '" - | '
    if edit then
        return exec(cmd .. "swappy -f - && " .. scripts .. "/copy_latest_img.sh")
    end
    return exec(cmd .. "wl-copy")
end
hl.bind("SUPER + S",         shot("$(slurp)", false))
hl.bind("SUPER + CTRL + S",  shot("$(slurp)", true))
hl.bind("SUPER + W",         shot(winGeom, false))
hl.bind("SUPER + CTRL + W",  shot(winGeom, true))
hl.bind("SUPER + M",         shot(monGeom, false))
hl.bind("SUPER + SHIFT + M", shot(monGeom, true))

-- Sxiva scratchpad (same as numpad 5) and the tagged main window.
hl.bind("ALT + S", exec(scripts .. "/scratchpad_toggle.sh 5"))
hl.bind("ALT + M", exec(scripts .. "/focus_main.sh"))

-- Numpad scratchpads (numlock off), via scratchpad_toggle.sh:
-- 1/2/3 firefox (main profile), 5 sxiva terminal, 7/8/9 terminals,
-- + - * / claude pads (each starting in ~/.config/my), 0 the last-used
-- pad. Every key is dual-function: tap = toggle, hold >=300ms = peek
-- (shows on keydown, hides on keyup). Needs a press + release bind per key:
-- press shows/hides, release hides only after a long press.
-- . tiles the visible (else last-used) pad onto the current workspace;
-- its key still summons the modal, and dismissing returns it to its
-- tile. . again on its home workspace un-tiles it back to a scratchpad.
local pad = scripts .. "/scratchpad_toggle.sh"
local padKeys = {
    { "KP_End",      "1" },
    { "KP_Down",     "2" },
    { "KP_Next",     "3" },
    { "KP_Begin",    "5" },
    { "KP_Home",     "7" },
    { "KP_Up",       "8" },
    { "KP_Prior",    "9" },
    { "KP_Insert",   "last" },
    { "KP_Add",      "claude1" },
    { "KP_Subtract", "claude2" },
    { "KP_Multiply", "claude3" },
    { "KP_Divide",   "claude4" },
}
for _, kp in ipairs(padKeys) do
    local key, name = kp[1], kp[2]
    hl.bind(key, exec(pad .. " press " .. name))
    hl.bind(key, exec(pad .. " release " .. name), { release = true })
end
hl.bind("KP_Delete", exec(pad .. " tile"))

-- Click outside a visible scratchpad hides it. MUST stay non-consuming:
-- a consuming bind here would swallow all left clicks.
hl.bind("mouse:272", exec(scripts .. "/scratchpad_click_check.sh"), { non_consuming = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Ignore maximize requests from all apps.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland.
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_initial_focus = true,
})

-- Scratchpad windows: 90% opacity, no active border, and no window
-- animations (pre-placement moves/resizes while hidden must not play out
-- during the reveal; the specialWorkspace fade is workspace-level and still
-- runs). Browsers are borderless; terminals keep their border.
local pads = { "browser1", "browser2", "browser3", "sxiva", "term7", "term8", "term9",
               "claude1", "claude2", "claude3", "claude4" }
for _, p in ipairs(pads) do
    local rule = {
        name    = "pad-" .. p,
        match   = { workspace = "special:S-" .. p },
        opacity = "0.9 0.9",
        no_anim = true,
    }
    if p:match("^browser") then
        rule.border_size = 0
    end
    hl.window_rule(rule)
end
