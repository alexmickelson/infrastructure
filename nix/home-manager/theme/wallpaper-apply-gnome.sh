#!/usr/bin/env bash
set -euo pipefail

image="$1"
path="$(realpath "$image")"
uri="file://${path// /%20}"

gsettings set org.gnome.desktop.background picture-uri "$uri"
gsettings set org.gnome.desktop.background picture-uri-dark "$uri"
gsettings set org.gnome.desktop.background picture-options zoom

accent_css="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/matugen.css"
if [[ ! -f $accent_css ]]; then
  exit 0
fi

hex="$(sed -nE 's/^@define-color accent_bg_color #([0-9a-fA-F]{6});$/\1/p' "$accent_css" | head -1)"
if [[ -z $hex ]]; then
  exit 0
fi

accent="$(gawk -v hex="$hex" '
  function abs(x) { return x < 0 ? -x : x }
  BEGIN {
    r = strtonum("0x" substr(hex, 1, 2)) / 255
    g = strtonum("0x" substr(hex, 3, 2)) / 255
    b = strtonum("0x" substr(hex, 5, 2)) / 255
    max = r > g ? (r > b ? r : b) : (g > b ? g : b)
    min = r < g ? (r < b ? r : b) : (g < b ? g : b)
    delta = max - min
    if (delta < 0.08) { print "slate"; exit }
    if (max == r) hue = 60 * ((g - b) / delta)
    else if (max == g) hue = 60 * (2 + (b - r) / delta)
    else hue = 60 * (4 + (r - g) / delta)
    if (hue < 0) hue += 360
    n = split("red orange yellow green teal blue purple pink", names, " ")
    split("2 30 48 132 188 218 285 330", refs, " ")
    best = names[1]; best_distance = 360
    for (i = 1; i <= n; i++) {
      distance = abs(hue - refs[i])
      if (distance > 180) distance = 360 - distance
      if (distance < best_distance) { best_distance = distance; best = names[i] }
    }
    print best
  }')"

if [[ -n $accent ]]; then
  gsettings set org.gnome.desktop.interface accent-color "$accent"
fi
