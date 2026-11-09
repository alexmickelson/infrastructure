#!/usr/bin/env bash
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

matugen image "$image"
