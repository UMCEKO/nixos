#!/usr/bin/env bash
# Bar dropdown toggler: dropdown.sh <class-regex> <width> <command...>
# First click spawns the app and anchors it top-right under the bar on the
# focused monitor; second click closes it. Positioning is done post-spawn via
# hl.dsp.window.move (the lua window-rule `move` field is a no-op in 0.55).
set -u
class=$1; width=$2; shift 2

addr=$(hyprctl clients -j | jq -r --arg c "$class" '.[] | select(.class|test($c)) | .address' | head -1)
if [ -n "$addr" ]; then
  hyprctl dispatch "hl.dsp.window.close({ window = \"address:$addr\" })" >/dev/null
  exit 0
fi

"$@" >/dev/null 2>&1 &

# wait for the window (up to 3s)
for _ in $(seq 1 30); do
  sleep 0.1
  addr=$(hyprctl clients -j | jq -r --arg c "$class" '.[] | select(.class|test($c)) | .address' | head -1)
  [ -n "$addr" ] && break
done
[ -z "$addr" ] && exit 1

# anchor top-right under the bar, on the focused monitor
read -r mx my mw < <(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.x) \(.y) \((.width/.scale)|floor)"')
x=$((mx + mw - width - 10))
y=$((my + 40))
hyprctl dispatch "hl.dsp.window.move({ x = $x, y = $y, window = \"address:$addr\" })" >/dev/null
