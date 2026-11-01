#!/usr/bin/env bash
set -uo pipefail

hyprctl reload

if ! hyprshell socat '"Reload"' > /dev/null 2>&1; then
  echo "hyprland-reload: hyprshell not running, window switcher binds not refreshed" >&2
fi
