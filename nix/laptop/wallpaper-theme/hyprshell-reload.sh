#!/usr/bin/env bash
set -uo pipefail

if ! hyprshell socat '"Reload"' > /dev/null 2>&1; then
  echo "hyprshell-reload: daemon not running, styles apply on next start" >&2
fi
