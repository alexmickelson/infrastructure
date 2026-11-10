#!/usr/bin/env bash
set -euo pipefail

controller=/sys/bus/pci/devices/0000:00:19.1

say() { printf '\n== %s ==\n' "$1"; }

say "GNOME touchpad send-events"
before="$(gsettings get org.gnome.desktop.peripherals.touchpad send-events || true)"
printf '  was: %s\n' "$before"
if [[ "$before" != "'enabled'" ]]; then
  gsettings set org.gnome.desktop.peripherals.touchpad send-events enabled
  printf '  now: %s\n' "$(gsettings get org.gnome.desktop.peripherals.touchpad send-events)"
else
  printf '  already enabled\n'
fi

if [[ "$(id -u)" -eq 0 ]]; then SUDO=""; else SUDO=sudo; fi

say "touchpad controller 0000:00:19.1 (pin in D0)"
printf '  was: %s\n' "$(cat "$controller/power/control")"
if [[ "$(cat "$controller/power/control")" != on ]]; then
  echo on | $SUDO tee "$controller/power/control" >/dev/null
  printf '  now: %s\n' "$(cat "$controller/power/control")"
fi

say "verdict (hands off the pad, sampling for 3s)"
node=""
for d in /sys/class/input/event*; do
  case "$(cat "$d/device/name" 2>/dev/null)" in
    "PIXA3854:00 093A:1343 Touchpad") node=/dev/input/$(basename "$d"); break ;;
  esac
done
if [[ -z "$node" ]]; then
  echo "  no PIXA3854 Touchpad input node found - device did not enumerate"
  exit 1
fi

read -r stats < <(timeout 3 cat "$node" | python3 -c '
import struct, sys
data = sys.stdin.buffer.read()
reports = touch_starts = positions = 0
for offset in range(0, len(data) - 23, 24):
    _, _, etype, code, value = struct.unpack_from("<QQHHi", data, offset)
    if etype == 1 and code == 330:
        touch_starts += 1 if value else 0
    elif etype == 3 and code in (47, 53, 54, 0, 1):
        positions += 1
    elif etype == 0 and code == 0:
        reports += 1
print(f"{len(data)} {reports} {touch_starts} {positions}")
')
read -r bytes reports touch_starts positions <<<"$stats"
printf '  %s bytes streamed, %s reports, %s touch starts, %s position events\n' \
  "$bytes" "$reports" "$touch_starts" "$positions"

if ((reports == 0)); then
  verdict="SILENT - pad idle (normal if untouched) or dead"
elif ((touch_starts == 0)); then
  verdict="FLOODING - empty/phantom reports, the wedge is active"
else
  verdict="GENERATING INPUT - pad is alive and sane"
fi
printf '  verdict: %s\n' "$verdict"
printf '  IRQ rate check:\n'
grep "designware.5" /proc/interrupts | awk '{print "    IRQ 21 total:", $2}'
echo
echo "  for a full report run: ./touchpad.sh"
