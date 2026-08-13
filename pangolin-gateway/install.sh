#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cron_tag="pangolin-gateway-managed-update"
cron_line="17 3 * * * /bin/bash -lc 'cd \"$repo_dir\" && git pull --ff-only && docker compose -f pangolin-gateway/docker-compose.yml up -d' >> /tmp/pangolin-gateway-update.log 2>&1 # $cron_tag"
current_crontab="$(crontab -l 2>/dev/null || true)"

if printf '%s\n' "$current_crontab" | grep -Fq "# $cron_tag"; then
  printf 'Daily Pangolin update cron job already installed.\n'
  exit 0
fi

printf '%s\n%s\n' "$current_crontab" "$cron_line" | crontab -
printf 'Installed daily Pangolin update cron job (03:17 local VPS time).\n'
