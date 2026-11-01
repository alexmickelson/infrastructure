#!/usr/bin/env bash
set -euo pipefail

source_dir="${XDG_CACHE_HOME:-$HOME/.cache}/matugen/firefox"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

find_profiles_ini() {
  for candidate in "$config_home/mozilla/firefox/profiles.ini" "$HOME/.mozilla/firefox/profiles.ini"; do
    if [[ -f $candidate ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

if ! profiles_ini="$(find_profiles_ini)"; then
  echo "firefox-theme: no profiles.ini found" >&2
  exit 0
fi

if [[ ! -d $source_dir ]]; then
  echo "firefox-theme: no generated theme in $source_dir" >&2
  exit 1
fi

profiles_root="$(dirname "$profiles_ini")"
applied=0

while IFS= read -r profile_path; do
  if [[ $profile_path = /* ]]; then
    profile_dir="$profile_path"
  else
    profile_dir="$profiles_root/$profile_path"
  fi
  if [[ ! -d $profile_dir ]]; then
    continue
  fi

  install -d "$profile_dir/chrome"
  for file in userChrome.css userContent.css; do
    if [[ -f "$source_dir/$file" ]]; then
      install -m 0644 "$source_dir/$file" "$profile_dir/chrome/$file"
    fi
  done

  user_js="$profile_dir/user.js"
  touch "$user_js"
  if ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$user_js"; then
    printf '%s\n' 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$user_js"
  fi
  if ! grep -q "ui.systemUsesDarkTheme" "$user_js"; then
    printf '%s\n' 'user_pref("ui.systemUsesDarkTheme", 1);' >> "$user_js"
  fi

  applied=$((applied + 1))
done < <(awk -F'=' '/^Path=/{print substr($0, index($0, "=") + 1)}' "$profiles_ini")

if [[ $applied -eq 0 ]]; then
  echo "firefox-theme: no usable profiles in $profiles_ini" >&2
  exit 1
fi

if pgrep -x firefox > /dev/null 2>&1; then
  echo "firefox-theme: theme written for $applied profile(s); restart Firefox to apply" >&2
fi
