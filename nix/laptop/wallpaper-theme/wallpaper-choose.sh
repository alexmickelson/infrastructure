#!/usr/bin/env bash
set -euo pipefail

wallpaper_dir="${WALLPAPER_DIR:-$HOME/Documents/wallpaper}"

if ! image="$(kdialog --title "Set wallpaper" --getopenfilename "$wallpaper_dir" "image/png image/jpeg image/webp image/avif image/gif")"; then
  exit 0
fi

if [[ -z $image ]]; then
  exit 0
fi

wallpaper-theme "$image"
