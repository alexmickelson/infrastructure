#!/usr/bin/env bash
set -uo pipefail

signal="${1:-USR2}"
reloaded=0

while read -r pid; do
  exe=$(readlink -f "/proc/$pid/exe" 2>/dev/null) || continue
  case ${exe##*/} in
    ghostty | .ghostty-wrapped)
      if kill -"$signal" "$pid" 2>/dev/null; then
        reloaded=1
      fi
      ;;
  esac
done < <(pgrep -f -i ghostty || true)

if ((reloaded == 0)); then
  echo "ghostty-reload: no running ghostty instance" >&2
fi
