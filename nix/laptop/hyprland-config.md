# Hyprland config examples

These are copy-paste examples for the packages installed by `desktop.nix`. Nothing here is applied automatically. Add sections to your config one at a time and run:

```bash
hyprctl reload
```

The flake currently resolves Hyprland 0.56.2, so these examples use standard `hyprland.conf` syntax.

Suggested order:

1. Fix the stock `Super + M` exit bind.
2. Add `Super + T` / `Super + Return` for Ghostty.
3. Add the `exec-once` programs.
4. Add the rest once things feel stable.

## 1. Hyprland core

File: `~/.config/hypr/hyprland.conf`

Merge these into the generated config. If a bind already exists, replace the generated line instead of adding a duplicate.

```ini
monitor = ,preferred,auto,1

$mainMod = SUPER
$terminal = ghostty
$fileManager = dolphin
$menu = wofi --show drun

env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORM,wayland;xcb

exec-once = waybar
exec-once = mako
exec-once = hyprpaper
exec-once = hypridle
exec-once = swayosd-server
exec-once = wl-paste --watch cliphist store
exec-once = wl-clip-persist --clipboard regular

input {
    kb_layout = us
    follow_mouse = 1
    sensitivity = 0

    touchpad {
        natural_scroll = true
        tap-to-click = true
    }
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(89b4faff)
    col.inactive_border = rgba(45475aaa)
    layout = dwindle
}

decoration {
    rounding = 8
    active_opacity = 1.0
    inactive_opacity = 0.97

    blur {
        enabled = true
        size = 4
        passes = 2
    }
}

dwindle {
    pseudotile = true
    preserve_split = true
}

misc {
    disable_hyprland_logo = true
    force_default_wallpaper = 0
}

bind = $mainMod, Return, exec, $terminal
bind = $mainMod, T, exec, $terminal
bind = $mainMod, Q, killactive,
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, D, exec, $menu
bind = $mainMod, Space, exec, $menu
bind = $mainMod, R, exec, hyprlauncher
bind = $mainMod, V, togglefloating,
bind = $mainMod, M, fullscreen, 1
bind = $mainMod SHIFT, E, exit,
bind = $mainMod, L, exec, hyprlock
bind = $mainMod, S, togglesplit,
bind = $mainMod, P, pseudo,

bind = ALT, Tab, cyclenext,
bind = ALT SHIFT, Tab, cyclenext, prev

bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

bind = $mainMod SHIFT, left, movewindow, l
bind = $mainMod SHIFT, right, movewindow, r
bind = $mainMod SHIFT, up, movewindow, u
bind = $mainMod SHIFT, down, movewindow, d

bind = $mainMod CTRL, left, resizeactive, -40 0
bind = $mainMod CTRL, right, resizeactive, 40 0
bind = $mainMod CTRL, up, resizeactive, 0 -40
bind = $mainMod CTRL, down, resizeactive, 0 40

bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9

bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

bindel = , XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise
bindel = , XF86AudioLowerVolume, exec, swayosd-client --output-volume lower
bindel = , XF86AudioMute, exec, swayosd-client --output-volume mute-toggle
bindel = , XF86MonBrightnessUp, exec, swayosd-client --brightness raise
bindel = , XF86MonBrightnessDown, exec, swayosd-client --brightness lower

bind = , Print, exec, grimblast --notify copy area
bind = SHIFT, Print, exec, grimblast --notify copy output
bind = $mainMod, Print, exec, grimblast --notify copy active
```

If `grimblast` complains about `--notify`, remove that flag.

## 2. Waybar

Files:

- `~/.config/waybar/config.jsonc`
- `~/.config/waybar/style.css`

The bar is started by `exec-once = waybar` in the Hyprland config above.

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

Started by `exec-once = mako` above.

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

Started by `exec-once = hyprpaper` above.

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

```ini
exec-once = wl-paste --watch cliphist store
# optional: keep clipboard contents after the source app closes
exec-once = wl-clip-persist --clipboard regular
```

Bind it to a picker:

```ini
bind = $mainMod SHIFT, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy
```

Inspect history directly:

```bash
cliphist list
```

## 7. Volume and brightness OSD

`swayosd` is installed. It needs the daemon:

```ini
exec-once = swayosd-server
```

The volume and brightness binds are already in the core config:

```ini
bindel = , XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise
bindel = , XF86AudioLowerVolume, exec, swayosd-client --output-volume lower
bindel = , XF86AudioMute, exec, swayosd-client --output-volume mute-toggle
bindel = , XF86MonBrightnessUp, exec, swayosd-client --brightness raise
bindel = , XF86MonBrightnessDown, exec, swayosd-client --brightness lower
```

## 8. Screenshots and color picker

`grimblast`, `grim`, `slurp`, and `hyprpicker` are installed.

Screenshot binds:

```ini
bind = , Print, exec, grimblast --notify copy area
bind = SHIFT, Print, exec, grimblast --notify copy output
bind = $mainMod, Print, exec, grimblast --notify copy active
```

Useful manual commands:

```bash
grimblast copy area
grimblast save area
hyprpicker -a
```

## 9. Already handled by NixOS

You do not need manual config for:

- `xdg-desktop-portal-hyprland` — enabled by the Hyprland NixOS module
- `xdg-desktop-portal-gtk` — installed for file pickers
- `hyprpolkitagent` — started as a systemd user service
- `xdg-desktop-portal` config

## 10. Quick verification

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
