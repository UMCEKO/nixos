#!/usr/bin/env bash
# rofi window picker; niri port of hypr/scripts/focus.sh.
set -euo pipefail

windows=$(niri msg -j windows)
idx=$(jq -r '.[] | .title // ""' <<<"$windows" |
  rofi -dmenu -format i -config ~/.config/rofi/config-compact.rasi -no-show-icons -i -p "Active Window") || exit 0
[ -n "$idx" ] || exit 0
niri msg action focus-window --id "$(jq ".[$idx].id" <<<"$windows")"
