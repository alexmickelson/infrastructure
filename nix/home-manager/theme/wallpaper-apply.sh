#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: wallpaper-apply <image>" >&2
  exit 2
fi

applied=0
for applier in wallpaper-apply-plasma wallpaper-apply-gnome; do
  if ! command -v "$applier" >/dev/null; then
    continue
  fi
  "$applier" "$1"
  applied=$((applied + 1))
done

if ((applied == 0)); then
  echo "wallpaper-apply: no desktop backend enabled (wallpaperTheme.gnome.enable / wallpaperTheme.kde.enable)" >&2
  exit 1
fi
