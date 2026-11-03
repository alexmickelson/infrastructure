#!/usr/bin/env bash
set -uo pipefail

reloaded=0

while read -r pid; do
  exe=$(readlink -f "/proc/$pid/exe" 2>/dev/null) || continue
  case ${exe##*/} in
    waybar | .waybar-wrapped)
      if kill -USR2 "$pid" 2>/dev/null; then
        reloaded=1
      fi
      ;;
  esac
done < <(pgrep -f -i waybar || true)

if ((reloaded == 0)); then
  echo "waybar-reload: no running waybar instance" >&2
fi
