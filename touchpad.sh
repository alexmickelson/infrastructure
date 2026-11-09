#!/usr/bin/env bash
set -uo pipefail

TOUCHPAD_NAME="PIXA3854:00 093A:1343 Touchpad"
TOUCHPAD_HID_GLOB="0018:093A:1343.*"
I2C_DRIVER=i2c_hid_acpi
OUT=${OUT:-/tmp/touchpad-$(date +%Y%m%d-%H%M%S).log}
SAMPLE_SECONDS=${SAMPLE_SECONDS:-3}
IRQ_SECONDS=${IRQ_SECONDS:-5}
DO_REBIND=0
DO_RESET=0
DO_PM=0
DO_WATCH=0
[ "${1:-}" = "--rebind" ] && DO_REBIND=1
[ "${1:-}" = "--reset" ] && DO_RESET=1
[ "${1:-}" = "--pm" ] && DO_PM=1
[ "${1:-}" = "--watch" ] && DO_WATCH=1

discover() {
  hid=""
  i2c_dev=""
  event=""
  for candidate in /sys/bus/hid/devices/${TOUCHPAD_HID_GLOB}; do
    [ -e "$candidate" ] || continue
    hid=$candidate
    break
  done
  [ -n "$hid" ] || return 0
  i2c_dev=$(basename "$(dirname "$(readlink -f "$hid")")")
  for node in "$hid"/input/input*/event*; do
    [ -e "$node" ] || continue
    if [ "$(cat "$(dirname "$node")/name" 2>/dev/null)" = "$TOUCHPAD_NAME" ]; then
      event=/dev/input/$(basename "$node")
    fi
  done
}

sample_events() {
  local node=$1 seconds=$2
  if [ ! -e "$node" ]; then
    echo "  $node: MISSING"
    return 1
  fi
  python3 - "$node" "$seconds" <<'PY'
import collections, select, struct, sys, time
path, secs = sys.argv[1], float(sys.argv[2])
names = {
    (0, 0): "SYN_REPORT",
    (4, 5): "MSC_TIMESTAMP",
    (1, 272): "BTN_LEFT",
    (1, 325): "BTN_TOOL_FINGER",
    (1, 330): "BTN_TOUCH",
    (1, 333): "BTN_TOOL_DOUBLETAP",
    (1, 334): "BTN_TOOL_TRIPLETAP",
    (3, 47): "ABS_MT_SLOT",
    (3, 48): "ABS_MT_TOUCH_MAJOR",
    (3, 49): "ABS_MT_TOUCH_MINOR",
    (3, 50): "ABS_MT_WIDTH_MAJOR",
    (3, 51): "ABS_MT_WIDTH_MINOR",
    (3, 52): "ABS_MT_ORIENTATION",
    (3, 53): "ABS_MT_POSITION_X",
    (3, 54): "ABS_MT_POSITION_Y",
    (3, 55): "ABS_MT_TOOL_TYPE",
    (3, 56): "ABS_MT_BLOB_ID",
    (3, 57): "ABS_MT_TRACKING_ID",
    (3, 58): "ABS_MT_PRESSURE",
    (3, 59): "ABS_MT_DISTANCE",
    (3, 0): "ABS_X",
    (3, 1): "ABS_Y",
}
kindnames = {0: "SYN", 1: "KEY", 2: "REL", 3: "ABS", 4: "MSC", 17: "LED"}
size = struct.calcsize("llHHi")
counts = collections.Counter()
touches = lifts = 0
total = 0
deadline = time.time() + secs
with open(path, "rb", buffering=0) as fd:
    while time.time() < deadline:
        if not select.select([fd], [], [], 0.2)[0]:
            continue
        chunk = fd.read(size)
        if len(chunk) < size:
            break
        _, _, kind, code, value = struct.unpack("llHHi", chunk)
        counts[names.get((kind, code), f"{kindnames.get(kind, kind)}:{code}")] += 1
        if (kind, code) == (3, 57):
            touches += value >= 0
            lifts += value < 0
        total += 1
rate = total / secs
motion = sum(v for k, v in counts.items() if k.startswith("ABS_MT_POSITION"))
print(f"  {path}: {total} events in {secs:g}s ({rate:.0f}/s)")
for key, value in counts.most_common(14):
    print(f"    {key}: {value}")
print(f"    touch sequences: {touches} start, {lifts} lift, {motion} position updates")
if not total:
    print("  verdict: SILENT - no reports at all (idle pad, or dead device)")
elif not counts["BTN_TOUCH"] and not motion:
    print("  verdict: STUCK - empty timestamp reports only, no touch data")
elif not counts["BTN_TOUCH"]:
    print("  verdict: CORRUPT - position data without BTN_TOUCH framing")
else:
    print("  verdict: REPORTING TOUCHES")
PY
}

sample_irq() {
  local pattern=$1 seconds=$2
  local before after
  before=$(grep -E "$pattern" /proc/interrupts | awk '{for (i = 2; i <= NF; i++) if ($i ~ /^[0-9]+$/) sum += $i} END {print sum+0}')
  sleep "$seconds"
  after=$(grep -E "$pattern" /proc/interrupts | awk '{for (i = 2; i <= NF; i++) if ($i ~ /^[0-9]+$/) sum += $i} END {print sum+0}')
  echo "  ${pattern}: $((after - before)) interrupts in ${seconds}s (total $after)"
}

report() {
  echo "== context =="
  date -Is
  uname -srm
  uptime
  echo

  echo "== touchpad bindings =="
  discover
  echo "  hid device : ${hid:-MISSING}"
  echo "  i2c client : ${i2c_dev:-MISSING}"
  echo "  event node : ${event:-MISSING}"
  for path in "/sys/bus/i2c/devices/${i2c_dev}/driver" "${hid}/driver"; do
    [ -n "${i2c_dev}${hid}" ] && [ -e "$path" ] && echo "  driver     : $(basename "$(readlink -f "$path")") ($path)"
  done
  echo

  echo "== suspend/resume timeline (this boot) =="
  journalctl -b 0 --no-pager -o short-iso 2>/dev/null |
    grep -E "PM: suspend (entry|exit)|Lid (opened|closed)|PrepareForSleep" |
    tail -12 | sed 's/^/  /'
  echo

  echo "== kernel messages since last resume =="
  journalctl -b 0 -k --no-pager -o short-iso 2>/dev/null |
    awk '/PM: suspend exit/{buf=""} {buf=buf $0 "\n"} END {printf "%s", buf}' |
    grep -iE "hid|i2c|input:|spd5118|lpss|timeout" | sed 's/^/  /'
  echo

  echo "== libinput/journal notes (this boot) =="
  journalctl -b 0 --no-pager -o short-iso 2>/dev/null |
    grep -iE "Libinput.*(PIXA3854|Touchpad)" | sed 's/^/  /'
  echo

  echo "== interrupt activity =="
  grep -E "i2c_designware" /proc/interrupts | sed 's/^/  /'
  sample_irq "i2c_designware.5" "$IRQ_SECONDS"
  echo

  echo "== raw events: touchpad (keep hands off the pad) =="
  sample_events "$event" "$SAMPLE_SECONDS"
  echo

  echo "== raw events: touchscreen reference =="
  sample_events /dev/input/by-path/pci-0000:00:19.0-platform-i2c_designware.4-event "$SAMPLE_SECONDS"
  echo
}

rebind() {
  if [ "$(id -u)" != "0" ]; then
    echo "== rebind: needs root, re-run as: sudo $0 --rebind (writes its own log) =="
    return 0
  fi
  discover
  if [ -z "$i2c_dev" ]; then
    echo "== rebind: touchpad not bound, loading $I2C_DRIVER =="
    modprobe -r "$I2C_DRIVER" 2>/dev/null
    modprobe "$I2C_DRIVER"
    sleep 1
    return 0
  fi
  echo "== rebind: $i2c_dev via $I2C_DRIVER =="
  touchpad_detach
  touchpad_attach
  sleep 1
}

touchpad_detach() {
  if [ -w "/sys/bus/i2c/drivers/${I2C_DRIVER}/unbind" ] && [ -e "/sys/bus/i2c/drivers/${I2C_DRIVER}/${i2c_dev}" ]; then
    echo "$i2c_dev" >"/sys/bus/i2c/drivers/${I2C_DRIVER}/unbind"
  else
    modprobe -r "$I2C_DRIVER" 2>/dev/null
  fi
}

touchpad_attach() {
  if [ -w "/sys/bus/i2c/drivers/${I2C_DRIVER}/bind" ] && [ ! -e "/sys/bus/i2c/drivers/${I2C_DRIVER}/${i2c_dev}" ] && [ -d "/sys/bus/i2c/devices/${i2c_dev}" ]; then
    echo "$i2c_dev" >"/sys/bus/i2c/drivers/${I2C_DRIVER}/bind"
  else
    modprobe "$I2C_DRIVER" 2>/dev/null
  fi
}

controller_path() {
  local resolved
  resolved=$(readlink -f "/sys/bus/i2c/devices/${i2c_dev}" 2>/dev/null)
  echo "$resolved" | grep -oE '[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9]' | head -1
}

reset_controller() {
  if [ "$(id -u)" != "0" ]; then
    echo "== reset: needs root, re-run as: sudo $0 --reset (writes its own log) =="
    return 0
  fi
  discover
  if [ -z "$i2c_dev" ]; then
    echo "== reset: touchpad not bound, nothing to reset =="
    return 0
  fi
  local pci_dev pci_driver
  pci_dev=$(controller_path)
  if [ -z "$pci_dev" ] || [ ! -e "/sys/bus/pci/devices/${pci_dev}" ]; then
    echo "== reset: could not resolve i2c controller, falling back to rebind =="
    rebind
    return 0
  fi
  pci_driver=$(basename "$(readlink -f "/sys/bus/pci/devices/${pci_dev}/driver")")
  echo "== reset: $i2c_dev + controller $pci_dev ($pci_driver) =="
  touchpad_detach
  echo "$pci_dev" >"/sys/bus/pci/drivers/${pci_driver}/unbind"
  sleep 2
  echo "$pci_dev" >"/sys/bus/pci/drivers/${pci_driver}/bind"
  sleep 2
  discover
  if [ -z "$hid" ]; then
    echo "== reset: controller came back but touchpad did not enumerate; a reboot is needed =="
  fi
}

runtime_pm_off() {
  if [ "$(id -u)" != "0" ]; then
    echo "== pm: needs root, re-run as: sudo $0 --pm (writes its own log) =="
    return 0
  fi
  discover
  if [ -z "$i2c_dev" ]; then
    echo "== pm: touchpad not bound, skipping =="
    return 0
  fi
  local adapter
  adapter=$(basename "$(dirname "$(readlink -f "/sys/bus/i2c/devices/${i2c_dev}")")")
  echo "== pm: disabling runtime autosuspend for ${i2c_dev} ${adapter} =="
  for path in "/sys/bus/i2c/devices/${i2c_dev}" "/sys/bus/i2c/devices/${adapter}" "${hid}"; do
    [ -w "${path}/power/control" ] || continue
    echo on >"${path}/power/control"
    echo "  ${path}: control=$(cat "${path}/power/control") runtime_status=$(cat "${path}/power/runtime_status" 2>/dev/null)"
  done
}

watch_loop() {
  local iterations=${WATCH_ITERATIONS:-0} count=0 verdict
  while :; do
    discover
    verdict=$(sample_events "$event" "$SAMPLE_SECONDS" | grep -E "verdict|touch sequences" | tr '\n' ' ')
    echo "$(date +%H:%M:%S) ${verdict:-no sample}"
    count=$((count + 1))
    if [ "$iterations" -gt 0 ] && [ "$count" -ge "$iterations" ]; then
      break
    fi
    sleep "${WATCH_PAUSE:-15}"
  done
}

main() {
  if [ "$DO_WATCH" = 1 ]; then
    watch_loop
    return 0
  fi
  report
  if [ "$DO_RESET" = 1 ]; then
    reset_controller
    runtime_pm_off
    report
  elif [ "$DO_PM" = 1 ]; then
    runtime_pm_off
    report
  elif [ "$DO_REBIND" = 1 ]; then
    rebind
    report
  else
    echo "== modes: --rebind (i2c client), --reset (client + controller power-cycle), --pm (runtime PM off), --watch (timestamped verdicts) =="
  fi
}

main 2>&1 | tee "$OUT"
chmod 0644 "$OUT" 2>/dev/null || true
echo "log: $OUT"
