#! /usr/bin/env nix-shell
#! nix-shell -i bash -p gnome-monitor-config dialog newt bash

set -euo pipefail

# === Config ===
APP_NAME="GNOME Monitor TUI"
SNAP_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/monitor-tui"
mkdir -p "$SNAP_DIR"

# === UI helpers (dialog -> whiptail -> plain) ===
have() { command -v "$1" >/dev/null 2>&1; }
UI=""
if have dialog; then UI="dialog"
elif have whiptail; then UI="whiptail"
else UI="plain"; fi

# Provide a short, useful description for a connector (status, primary, resolution)
describe_connector() {
  local c="$1"
  local desc=""
  if have xrandr; then
    local line
    line="$(xrandr --query 2>/dev/null | grep -E "^${c}\\b" | head -n1 || true)"
    if [ -n "$line" ]; then
      local status
      status="$(awk '{print $2}' <<<"$line")"
      local primary=""
      grep -q " primary " <<<"$line" && primary=" primary"
      local respos
      respos="$(grep -Eo '[0-9]{3,}x[0-9]{3,}\+[0-9]+\+[0-9]+' <<<"$line" | head -n1)"
      [ -n "$respos" ] && respos=" $respos"
      desc="[$status$primary$respos]"
    fi
  fi
  if [ -z "$desc" ] && have gnome-monitor-config; then
    local gline
    gline="$(gnome-monitor-config list 2>/dev/null | grep -E "\\b${c}\\b" | head -n1 || true)"
    if [ -n "$gline" ]; then
      local wh
      wh="$(echo "$gline" | grep -Eo '[0-9]{3,}x[0-9]{3,}@?[0-9.]*' | head -n1)"
      if [ -n "$wh" ]; then desc="[present $wh]"; else desc="[present]"; fi
    fi
  fi
  [ -z "$desc" ] && desc="[present]"
  case "$c" in eDP-*) desc="$desc internal" ;; esac
  echo "$desc"
}

title() { printf "%s\n" "$1"; }
msgbox() {
  local text="$1"
  case "$UI" in
    dialog) dialog --title "$APP_NAME" --msgbox "$text" 10 70 ;;
    whiptail) whiptail --title "$APP_NAME" --msgbox "$text" 10 70 ;;
    plain) printf "\n== %s ==\n%s\n\n" "$APP_NAME" "$text"; read -rp "Press Enter..." ;;
  esac
}
inputbox() {
  local prompt="$1" default="${2:-}"
  case "$UI" in
    dialog) dialog --title "$APP_NAME" --inputbox "$prompt" 10 70 "$default" 3>&1 1>&2 2>&3 ;;
    whiptail) whiptail --title "$APP_NAME" --inputbox "$prompt" 10 70 "$default" 3>&1 1>&2 2>&3 ;;
    plain) read -rp "$prompt [$default]: " ans; echo "${ans:-$default}" ;;
  esac
}
menu() {
  # args: prompt  key1 "desc1" key2 "desc2" ...
  local prompt="$1"; shift
  case "$UI" in
    dialog) dialog --title "$APP_NAME" --menu "$prompt" 20 70 12 "$@" 3>&1 1>&2 2>&3 ;;
    whiptail) whiptail --title "$APP_NAME" --menu "$prompt" 20 70 12 "$@" 3>&1 1>&2 2>&3 ;;
    plain)
      echo; echo "$prompt"
      local i=1 opts=() keys=()
      while [ "$#" -gt 0 ]; do keys+=("$1"); shift; opts+=("$i) $1"); shift; i=$((i+1)); done
      for o in "${opts[@]}"; do echo "  $o"; done
      read -rp "Choose 1-$((i-1)): " ix
      echo "${keys[$((ix-1))]}"
      ;;
  esac
}
checklist() {
  # returns space-separated chosen keys
  local prompt="$1"; shift
  case "$UI" in
    dialog)
      dialog --title "$APP_NAME" --checklist "$prompt" 20 70 12 "$@" 3>&1 1>&2 2>&3 | tr -d '"'
      ;;
    whiptail)
      whiptail --title "$APP_NAME" --checklist "$prompt" 20 70 12 "$@" 3>&1 1>&2 2>&3 | tr -d '"'
      ;;
    plain)
      echo; echo "$prompt"
      local idx=1 keys=() descs=()
      while [ "$#" -gt 0 ]; do
        keys+=("$1"); shift
        [ "$#" -gt 0 ] && descs+=("$1") && shift || break
        [ "$#" -gt 0 ] && shift || break  # skip ON/OFF
      done
      for k in "${!keys[@]}"; do echo "  [ ] $((k+1)) ${keys[$k]}  ${descs[$k]}"; done
      read -rp "Enter numbers to select (e.g. 1 3): " picks
      local out=""
      for n in $picks; do out+="${keys[$((n-1))]} "; done
      echo "$out"
      ;;
  esac
}

# === Discover connectors ===
discover_connectors() {
  # Try gnome-monitor-config output first, then fallbacks
  local out=""
  if have gnome-monitor-config; then
    # tolerant scrape for common connector names
    out="$(gnome-monitor-config list 2>/dev/null | grep -Eo '\b(HDMI|DP|eDP|VGA|DVI|USB-C)(-[0-9]+)\b' | sort -u || true)"
  fi
  if [ -z "$out" ] && have xrandr; then
    out="$(xrandr --listmonitors 2>/dev/null | grep -Eo '\b(HDMI|DP|eDP|VGA|DVI|USB-C)(-[0-9]+)\b' | sort -u || true)"
  fi
  if [ -z "$out" ]; then
    msgbox "Couldn't auto-detect connectors. You'll be asked to type names like: DP-3, DP-10, eDP-1"
    local manual
    manual="$(inputbox "Enter connector names (space-separated):" "DP-3 DP-10 eDP-1")"
    out="$manual"
  fi
  echo "$out"
}

# === Build gnome-monitor-config command from choices ===
build_command() {
  local mirror_group="$1"; shift
  local placement="$1"; shift   # below/above/left/right
  local offset_default_y="$1"; shift
  local offset_default_x="$1"; shift
  local others=("$@")

  local cmd=(gnome-monitor-config set)

  # First logical monitor: mirrored group as PRIMARY at 0,0
  local L1=(-Lp)
  for m in $mirror_group; do L1+=(-M "$m"); done
  L1+=(-x 0 -y 0)
  cmd+=("${L1[@]}")

  # Place others relative to group
  for o in "${others[@]}"; do
    [ -z "$o" ] && continue
    local x=0 y=0
    case "$placement" in
      below) y="$offset_default_y"; x="$offset_default_x" ;;
      above) y="-$offset_default_y"; x="$offset_default_x" ;;
      right) x="$offset_default_x"; y="$offset_default_y" ;;
      left)  x="-$offset_default_x"; y="$offset_default_y" ;;
      *)     y="$offset_default_y"; x="$offset_default_x" ;;
    esac
    cmd+=(-L -M "$o" -x "$x" -y "$y")
  done

  printf "%q " "${cmd[@]}"
}

# === Snapshots ===
snapshot_save() {
  local label="$1" cmdline="$2"
  local file="$SNAP_DIR/$(echo "$label" | tr '[:space:]' '_' | tr -cd '[:alnum:]_-.').sh"
  cat >"$file" <<EOF
#!/usr/bin/env bash
set -euo pipefail
$cmdline
EOF
  chmod +x "$file"
  echo "$file"
}
snapshot_pick() {
  # List saved snapshot scripts and allow the user to pick one
  # Avoid invalid array assignment with redirections; just check with compgen/ls
  if ! ls "$SNAP_DIR"/*.sh >/dev/null 2>&1; then
    msgbox "No snapshots saved yet."
    return 1
  fi

  local menu_args=()
  for f in "$SNAP_DIR"/*.sh; do
    local base; base="$(basename "$f")"
    menu_args+=("$base" "apply/delete")
  done
  local pick
  pick="$(menu "Snapshots:" "${menu_args[@]}")" || return 1
  echo "$SNAP_DIR/$pick"
}

# === Main flow ===
main_menu() {
  while true; do
    case "$(menu "Choose an action:" \
      new "Create & apply a new layout" \
      apply "Apply a saved snapshot" \
      delete "Delete a saved snapshot" \
      quit "Quit")" in
      new)
        new_layout
        ;;
      apply)
        local f; f="$(snapshot_pick)" || continue
        if [ -n "${f:-}" ]; then
          bash "$f" && msgbox "Applied snapshot: $(basename "$f")"
        fi
        ;;
      delete)
        local f; f="$(snapshot_pick)" || continue
        [ -n "${f:-}" ] && rm -f "$f" && msgbox "Deleted snapshot: $(basename "$f")"
        ;;
      quit|"")
        exit 0
        ;;
    esac
  done
}

new_layout() {
  local conns; conns="$(discover_connectors)"
  # build checklist args: key desc ON/OFF with additional info
  local cl_args=()
  for c in $conns; do
    local info; info="$(describe_connector "$c")"
    cl_args+=("$c" "$info" OFF)
  done
  local picked; picked="$(checklist "Pick one or more connectors to MIRROR as a single logical monitor (these will be your 'big' display):" "${cl_args[@]}")" || return
  if [ -z "$picked" ]; then msgbox "You must select at least one connector."; return; fi

  # Show a quick summary of current connectors before placement
  local summary=""
  for c in $conns; do summary+="$c $(describe_connector "$c")\n"; done
  msgbox "Detected connectors:\n$summary"

  # Pick placement for the remaining connectors
  local place; place="$(menu "Where do you want to place the OTHER monitors relative to the mirrored group?" \
    below "Below (typical laptop-under-desktop)" \
    above "Above" \
    left  "Left" \
    right "Right")" || return

  # Default offsets (you can tweak them)
  local offy offx
  offy="$(inputbox "Pixel offset for Y (distance from mirrored group). Example: 2160" "2160")"
  offx="$(inputbox "Pixel offset for X. Example: 0" "0")"

  # Others = conns not in picked
  read -ra all_arr <<<"$conns"
  read -ra pick_arr <<<"$picked"
  # build associative map for fast exclude
  declare -A is_pick; for p in "${pick_arr[@]}"; do is_pick["$p"]=1; done
  local others=()
  for a in "${all_arr[@]}"; do
    if [ -z "${is_pick[$a]+x}" ]; then others+=("$a"); fi
  done

  # Confirm which of the remaining to include (maybe none), showing info
  if [ "${#others[@]}" -gt 0 ]; then
    local cl2_args=()
    for o in "${others[@]}"; do
      local info; info="$(describe_connector "$o")"
      cl2_args+=("$o" "$info" ON)
    done
    local picked2; picked2="$(checklist "Select which of the remaining connectors to include (they will be placed $place the group):" "${cl2_args[@]}")" || picked2=""
    read -ra others <<<"$picked2"
  fi

  local cmdline; cmdline="$(build_command "$picked" "$place" "$offy" "$offx" "${others[@]:-}")"
  # Try to apply
  if $cmdline; then
    msgbox "Applied:\n$cmdline"
    # Offer to snapshot
    case "$(menu "Snapshot this working layout?" yes "Save snapshot" no "Skip")" in
      yes)
        local label; label="$(inputbox "Snapshot label:" "mirrored_group_$(date +%Y%m%d_%H%M%S)")"
        local file; file="$(snapshot_save "$label" "$cmdline")"
        msgbox "Saved snapshot: $file"
        ;;
      *) : ;;
    esac
  else
    msgbox "Failed to apply the layout.\nCommand was:\n$cmdline"
  fi
}

# === Checks ===
if ! have gnome-monitor-config; then
  msgbox "gnome-monitor-config is required (Wayland). Please install it (part of GNOME).\nAborting."
  exit 1
fi

main_menu
