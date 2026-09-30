hl.monitor({
  output = "HDMI-A-1",
  mode = "1920x1080@60",
  position = "0x0",
  scale = 1,
  vrr = 0,
})

hl.monitor({
  output = "Virtual-1",
  mode = "1920x1080@60",
  position = "1920x0",
  scale = 1,
  vrr = 0,
})

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 2,
    layout = "dwindle",
  },
  decoration = {
    rounding = 8,
    shadow = { enabled = true },
    blur = { enabled = true, size = 4, passes = 1 },
  },
  input = {
    kb_layout = "us",
    follow_mouse = 1,
  },
  misc = {
    disable_hyprland_logo = true,
    force_default_wallpaper = 0,
  },
  dwindle = {
    preserve_split = true,
  },
})

hl.window_rule({
  name = "float-all",
  match = { class = ".*" },
  float = true,
})

hl.bind("SUPER + T", hl.dsp.exec_cmd("ghostty"))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
hl.bind("SUPER + M", hl.dsp.exec_cmd("hyprctl dispatch fullscreen 1"))
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))

hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
  local key = i % 10
  hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
