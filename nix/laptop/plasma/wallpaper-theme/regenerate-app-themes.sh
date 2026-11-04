#!/usr/bin/env bash
# on-change-hook for kde-material-you-colors: regenerates the matugen-driven
# app themes (waybar, ghostty, kitty, gtk css, firefox) from the current
# wallpaper. The daemon passes no arguments, so the wallpaper comes from the
# recorded state file. Runs at daemon start and on every wallpaper change.
set -euo pipefail

state_file="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-theme/image"

if [[ ! -f $state_file ]]; then
  exit 0
fi

image="$(< "$state_file")"

if [[ ! -f $image ]]; then
  echo "regenerate-app-themes: recorded wallpaper is missing: $image" >&2
  exit 0
fi

exec matugen image "$image"
