# Hyprland Lua config examples

These are copy-paste examples for the packages installed by `desktop.nix`. Nothing here is applied automatically. Add sections to your config one at a time and run:

```bash
hyprctl reload
```

The flake currently resolves Hyprland 0.56.2, which uses Lua config at:

```text
~/.config/hypr/hyprland.lua
```

Suggested order:

1. Fix the stock `Super + M` exit bind.
2. Add `Super + T` / `Super + Return` for Ghostty.
3. Add the autostart block.
4. Add the rest once things feel stable.

## 1. Hyprland core

File: `~/.config/hypr/hyprland.lua`

Merge these into the generated Lua config. If a bind already exists, replace the generated line instead of adding a duplicate.

```lua
local terminal    = "ghostty"
local fileManager = "dolphin"
local menu        = "wofi --show drun"
local mainMod     = "SUPER"

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
end)

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,

        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    },

    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = "rgba(89b4faff)",
            inactive_border = "rgba(45475aaa)",
        },
        layout = "dwindle",
    },

    decoration = {
        rounding = 8,
        active_opacity = 1.0,
        inactive_opacity = 0.97,

        blur = {
            enabled = true,
            size = 4,
            passes = 2,
        },
    },

    dwindle = {
        pseudotile = true,
        preserve_split = true,
    },

    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
    },
})

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("hyprlauncher"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + S", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }))
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }))

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true, repeating = true })

hl.bind("Print", hl.dsp.exec_cmd("grimblast --notify copy area"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grimblast --notify copy output"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("grimblast --notify copy active"))
```

If `grimblast` complains about `--notify`, remove that flag.

## 2. Waybar

Files:

- `~/.config/waybar/config.jsonc`
- `~/.config/waybar/style.css`

The bar is started by the `hl.on("hyprland.start", ...)` block above.

### `~/.config/waybar/config.jsonc`

```jsonc
{
  "layer": "top",
  "position": "top",
  "height": 30,
  "spacing": 4,

  "modules-left": ["hyprland/workspaces", "hyprland/window"],
  "modules-center": ["clock"],
  "modules-right": ["pulseaudio", "network", "battery", "tray"],

  "hyprland/workspaces": {
    "format": "{name}",
    "on-click": "activate"
  },

  "hyprland/window": {
    "max-length": 50,
    "separate-outputs": true
  },

  "clock": {
    "format": "{:%H:%M}",
    "tooltip-format": "{:%A, %B %d, %Y}"
  },

  "pulseaudio": {
    "format": "{icon} {volume}%",
    "format-muted": " muted",
    "format-icons": ["", "", ""],
    "on-click": "pavucontrol"
  },

  "network": {
    "format-wifi": " {essid}",
    "format-ethernet": " ethernet",
    "format-disconnected": " offline",
    "tooltip-format": "{ifname} via {gwaddr}",
    "on-click": "nm-connection-editor"
  },

  "battery": {
    "format": "{capacity}% {icon}",
    "format-icons": ["", "", "", "", ""],
    "states": {
      "warning": 30,
      "critical": 15
    },
    "tooltip-format": "{timeTo} ({capacity}%)"
  },

  "tray": {
    "spacing": 8
  }
}
```

### `~/.config/waybar/style.css`

```css
* {
  font-family: "FiraCode Nerd Font", monospace;
  font-size: 13px;
  min-height: 0;
}

window#waybar {
  background: rgba(30, 30, 46, 0.92);
  color: #cdd6f4;
}

#workspaces button {
  padding: 0 8px;
  background: transparent;
  color: #cdd6f4;
  border: none;
  border-radius: 6px;
}

#workspaces button.active {
  background: #89b4fa;
  color: #1e1e2e;
}

#clock,
#pulseaudio,
#network,
#battery,
#tray {
  padding: 0 10px;
}

#battery.warning {
  color: #f9e2af;
}

#battery.critical {
  color: #f38ba8;
}
```

## 3. Notifications with mako

File: `~/.config/mako/config`

Started by `hl.exec_cmd("mako")` in the autostart block above.

```ini
max-visible=5
default-timeout=5000
anchor=top-right
margin=10
padding=10
width=350
height=150
border-size=2
border-radius=8
font=FiraCode Nerd Font 11
background-color=#1e1e2e
text-color=#cdd6f4
border-color=#89b4fa
```

Test it:

```bash
notify-send "Hyprland" "Notifications are working"
```

Useful commands:

```bash
makoctl dismiss
makoctl dismiss --all
```

## 4. Wallpaper with hyprpaper

File: `~/.config/hypr/hyprpaper.conf`

Use an absolute path. Hyprpaper does not reliably expand `~`.

```ini
preload = /home/alex/Pictures/wallpaper.png
wallpaper = ,/home/alex/Pictures/wallpaper.png
splash = false
```

Started by `hl.exec_cmd("hyprpaper")` in the autostart block above.

Reload after changing it:

```bash
hyprctl hyprpaper reload ,/home/alex/Pictures/wallpaper.png
```

## 5. Idle and lock

Files:

- `~/.config/hypr/hypridle.conf`
- `~/.config/hypr/hyprlock.conf`

### `~/.config/hypr/hypridle.conf`

```ini
general {
    lock_cmd = hyprlock
    before_sleep_cmd = hyprlock
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener {
    timeout = 300
    on-timeout = hyprlock
}

listener {
    timeout = 330
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
```

### `~/.config/hypr/hyprlock.conf`

```ini
background {
    monitor =
    path = /home/alex/Pictures/wallpaper.png
    blur_passes = 3
    blur_size = 8
}

input-field {
    monitor =
    size = 300, 50
    outline_thickness = 2
    dots_size = 0.2
    dots_spacing = 0.2
    dots_center = true
    outer_color = rgb(151515)
    inner_color = rgb(200, 200, 200)
    font_color = rgb(10, 10, 10)
    fade_on_empty = false
    placeholder_text = <i>Input Password...</i>
    hide_input = false
}

label {
    monitor =
    text = $TIME
    color = rgba(200, 200, 200, 1.0)
    font_size = 64
    font_family = FiraCode Nerd Font
    position = 0, 200
    halign = center
    valign = center
}
```

Test lock manually:

```bash
hyprlock
```

## 6. Clipboard history

`cliphist` and `wl-clipboard` are installed. The core config above starts the history watcher:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
end)
```

Bind it to a picker:

```lua
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))
```

Inspect history directly:

```bash
cliphist list
```

## 7. Volume and brightness OSD

`swayosd` is installed. It needs the daemon:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("swayosd-server")
end)
```

The volume and brightness binds are already in the core config:

```lua
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true, repeating = true })
```

## 8. Screenshots and color picker

`grimblast`, `grim`, `slurp`, and `hyprpicker` are installed.

Screenshot binds:

```lua
hl.bind("Print", hl.dsp.exec_cmd("grimblast --notify copy area"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grimblast --notify copy output"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("grimblast --notify copy active"))
```

Useful manual commands:

```bash
grimblast copy area
grimblast save area
hyprpicker -a
```

## 9. Monitors and rotation

`hyprmon` is installed and gives you a TUI for monitor layout, resolution, scale, orientation, mirroring, and profiles.

Run it from a terminal inside Hyprland:

```bash
hyprmon
```

Useful keys:

| Key | Action |
|---|---|
| `F` | Resolution and refresh rate |
| `C` / `D` | Advanced display settings, including transform/rotation |
| `R` | Scale |
| `A` | Apply live |
| `S` | Save to the active Hyprland config |
| `P` | Save the layout as a profile |
| `Q` | Quit |

`hyprmon` detects `~/.config/hypr/hyprland.lua` and writes monitor rules to `~/.config/hypr/hyprmon.lua` with a managed `require("hyprmon")` include.

If `hyprmon` owns your monitor layout:

- Keep the fallback rule in `hyprland.lua`:
  ```lua
  hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
  ```
- Remove explicit per-monitor `hl.monitor` blocks for monitors that `hyprmon` manages.
- Do not hand-edit `hyprmon.lua`; it is regenerated with a warning that manual changes may be overwritten.

The fallback catches monitors that have no explicit rule, such as a newly plugged-in display. `hyprmon` only writes rules for the monitors it knows about, so a new monitor will use the fallback until you configure and save it with `hyprmon`.

You can also configure monitors directly in Lua if you are not using `hyprmon`.

### Lua monitor config

```lua
hl.monitor({
    output = "eDP-1",
    mode = "preferred",
    position = "0x0",
    scale = 1,
    transform = 0,
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "2560x1440@144",
    position = "1920x0",
    scale = 1,
    transform = 0,
})
```

### Transform values

| Value | Orientation |
|---|---|
| `0` | Normal |
| `1` | 90 degrees |
| `2` | 180 degrees |
| `3` | 270 degrees |
| `4` | Flipped |
| `5` | Flipped 90 degrees |
| `6` | Flipped 180 degrees |
| `7` | Flipped 270 degrees |

Example: rotate the laptop panel 90 degrees:

```lua
hl.monitor({
    output = "eDP-1",
    mode = "preferred",
    position = "0x0",
    scale = 1,
    transform = 1,
})
```

The position is based on the scaled/transformed resolution. For example, a 1920x1080 monitor rotated to vertical occupies `1080x1920` in the layout.

Inspect connected monitors and their available modes:

```bash
hyprctl monitors
hyprctl monitors all
```

Apply a temporary monitor change without editing the config:

```bash
hyprctl keyword monitor "eDP-1, preferred, 0x0, 1, transform, 1"
```

Then save it permanently in your Lua config, or let `hyprmon` write it.

## 10. Already handled by NixOS

You do not need manual config for:

- `xdg-desktop-portal-hyprland` — enabled by the Hyprland NixOS module
- `xdg-desktop-portal-gtk` — installed for file pickers
- `hyprpolkitagent` — started as a systemd user service
- `xdg-desktop-portal` config

## 11. Quick verification

```bash
hyprctl reload
hyprctl binds
hyprctl monitors
systemctl --user status hyprpolkitagent
systemctl --user status xremap
```

If something does not start, run it manually from a terminal first:

```bash
waybar
mako
hyprpaper
hypridle
swayosd-server
```
