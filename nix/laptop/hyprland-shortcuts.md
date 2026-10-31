# Hyprland shortcut cheat sheet

The packages are installed by `desktop.nix`, but these bindings only become active after you add them to `~/.config/hypr/hyprland.lua` and run `hyprctl reload`.

## Stock Hyprland 0.56.2 defaults

These are the defaults from the generated Lua config. Check the real values with `hyprctl binds`.

| Shortcut | Action | Note |
|---|---|---|
| `Super + Q` | Open kitty | Stock default |
| `Super + C` | Close active window | Stock default |
| `Super + M` | Exit Hyprland | Stock default. Replace this first |
| `Super + E` | Open Dolphin | Stock default |
| `Super + V` | Toggle floating | Stock default |
| `Super + R` | Open hyprlauncher | Stock default |

> The stock `Super + M` exits your session. If you want `Super + M` for maximize, remove/change the exit bind before using it.

## Lua bind pattern

```lua
local mainMod = "SUPER"

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())
```

Use `hl.dsp.window.close()` for close, `hl.dsp.focus(...)` for focus, and `hl.dsp.window.move(...)` for moving windows. The full examples are in `hyprland-config.md`.

## Recommended personal bindings

These keep the old GNOME `Super + T` terminal habit and avoid the dangerous stock `Super + M` exit.

| Shortcut | Action |
|---|---|
| `Super + Return` | Open Ghostty |
| `Super + T` | Open Ghostty |
| `Super + Q` | Close active window |
| `Super + E` | Open Dolphin |
| `Super + D` | Open wofi app launcher |
| `Super + R` | Open hyprlauncher |
| `Super + Space` | Open wofi launcher |
| `Super + V` | Toggle floating |
| `Super + M` | Maximize/fullscreen window |
| `Super + Shift + E` | Exit Hyprland |
| `Super + L` | Lock with hyprlock |
| `Super + Shift + V` | Clipboard history picker |
| `Super + Shift + P` | Pick a color with hyprpicker |
| `Print` | Screenshot area to clipboard |
| `Shift + Print` | Screenshot full output to clipboard |
| `Super + Print` | Screenshot active window to clipboard |

## Window navigation

| Shortcut | Action |
|---|---|
| `Super + Left/Right/Up/Down` | Move focus |
| `Super + Shift + Left/Right/Up/Down` | Move window |
| `Super + Ctrl + Left/Right/Up/Down` | Resize window |
| `Super + 1..9` | Switch workspace |
| `Super + Shift + 1..9` | Move window to workspace |
| `Super + S` | Toggle split |
| `Super + P` | Toggle pseudo-tiling |
| `Alt + Tab` | Cycle windows forward |
| `Alt + Shift + Tab` | Cycle windows backward |

## Mouse

| Shortcut | Action |
|---|---|
| `Super + left drag` | Move window |
| `Super + right drag` | Resize window |
| `Super + scroll` | Switch workspace |

## Audio and brightness

These use `swayosd-server`, which must be running.

| Shortcut | Action |
|---|---|
| Volume up/down keys | Change volume with OSD |
| Mute key | Toggle mute with OSD |
| Brightness up/down keys | Change brightness with OSD |

## Everyday apps

| Shortcut | Action |
|---|---|
| `Super + T` / `Super + Return` | Ghostty |
| `Super + Q` | kitty, if you keep the stock bind |
| `Super + E` | Dolphin |
| `Super + D` / `Super + Space` | wofi |
| `Super + R` | hyprlauncher |
| `Super + L` | hyprlock |
| `Super + Shift + V` | cliphist picker |
| `Super + Shift + P` | hyprpicker |
| `Print` | grimblast area screenshot |

## Useful commands

```bash
hyprctl reload              # reload Hyprland config
hyprctl monitors            # list monitors
hyprctl clients             # list windows
hyprctl binds               # list active keybinds
hyprctl dispatch exec ghostty
makoctl dismiss --all       # clear notifications
cliphist list               # inspect clipboard history
```

## About xremap

Your existing `shortcuts.nix` remaps are separate from Hyprland:

- `Alt + A/C/F/Q/S/T/V/W/X/Z` still become `Ctrl + ...`
- Ghostty-specific `Alt + C` / `Alt + V` clipboard remaps still apply

Check it with:

```bash
systemctl --user status xremap
```

If xremap is not running, those Alt-based remaps won't work even though the Hyprland bindings do.
