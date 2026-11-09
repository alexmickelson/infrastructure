#!/usr/bin/env bash
set -euo pipefail

while IFS= read -r file; do
  if [[ ! -f $file ]]; then
    continue
  fi
  wallpaper-theme "$file"
  exit 0
done <<< "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}"

exit 1
