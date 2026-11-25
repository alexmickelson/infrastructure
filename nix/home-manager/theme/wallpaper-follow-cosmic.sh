#!/usr/bin/env bash
set -euo pipefail

backgrounds="${XDG_CONFIG_HOME:-$HOME/.config}/cosmic/com.system76.CosmicBackground/v1"
state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-theme"
state_file="$state_dir/image"

follow() {
  local handle candidate
  local -a handles=()

  shopt -s nullglob
  handles=( "$backgrounds"/* )
  shopt -u nullglob

  for handle in "${handles[@]}"; do
    candidate="$(sed -nE 's/^[[:space:]]*source:[[:space:]]*Path\("(.*)"\),?[[:space:]]*$/\1/p' "$handle" | head -1)"
    if [[ -z $candidate || ! -f $candidate ]]; then
      continue
    fi
    if [[ -f $state_file && "$(< "$state_file")" == "$candidate" ]]; then
      return 0
    fi

    mkdir -p "$state_dir"
    printf '%s\n' "$candidate" > "$state_file"
    systemctl --user start wallpaper-theme.service
    return 0
  done
}

mkdir -p "$backgrounds"
follow

inotifywait -m -q -e create -e close_write -e moved_to --format '%f' "$backgrounds" |
  while read -r; do
    sleep 0.3
    follow
  done
