#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-theme"
state_file="$state_dir/image"
wallpaper_dir="${WALLPAPER_DIR:-$HOME/Documents/wallpaper}"

if [[ $# -gt 0 ]]; then
  candidate="$1"
  if [[ ! -f $candidate && -f "$wallpaper_dir/$candidate" ]]; then
    candidate="$wallpaper_dir/$candidate"
  fi
  if [[ ! -f $candidate ]]; then
    echo "wallpaper-theme: image not found: $1 (also looked in $wallpaper_dir)" >&2
    exit 1
  fi
  image="$(realpath "$candidate")"
  mkdir -p "$state_dir"
  printf '%s\n' "$image" > "$state_file"
elif [[ -f $state_file ]]; then
  image="$(< "$state_file")"
  if [[ ! -f $image ]]; then
    echo "wallpaper-theme: recorded wallpaper is missing: $image" >&2
    echo "wallpaper-theme: run: wallpaper-theme <image>" >&2
    exit 1
  fi
else
  exit 0
fi

regenerate-app-themes
wallpaper-apply "$image"
