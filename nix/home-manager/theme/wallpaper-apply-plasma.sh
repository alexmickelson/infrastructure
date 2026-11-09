#!/usr/bin/env bash
set -euo pipefail

image="$1"

kwriteconfig6 --file kscreenlockerrc \
  --group Greeter --group Wallpaper --group org.kde.image --group General \
  --key Image "$image"

if ! pgrep -x plasmashell >/dev/null; then
  exit 0
fi

plasma-apply-wallpaperimage "$image"
