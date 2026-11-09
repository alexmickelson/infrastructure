#!/usr/bin/env bash
set -euo pipefail

wallpaper_dir="${WALLPAPER_DIR:-$HOME/Documents/wallpaper}"

picker=kdialog
if ! command -v kdialog >/dev/null; then
  picker=zenity
fi

case $picker in
  kdialog)
    image="$(kdialog --title "Set wallpaper" --getopenfilename "$wallpaper_dir" "image/png image/jpeg image/webp image/avif image/gif")" || exit 0
    ;;
  zenity)
    image="$(zenity --title "Set wallpaper" --file-selection "$wallpaper_dir/" \
      --file-filter='Images | *.png *.jpg *.jpeg *.webp *.avif *.gif')" || exit 0
    ;;
esac

if [[ -z $image ]]; then
  exit 0
fi

wallpaper-theme "$image"
