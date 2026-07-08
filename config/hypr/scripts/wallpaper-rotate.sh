#!/usr/bin/env bash
# One-shot: pick a fresh random image per monitor and apply it via awww.
# Drives one rotation tick. Looping/scheduling belongs in wallpaper-rotate.timer.
#
# Env knobs:
#   WP_DIR          (default: ~/Pictures/Wallpapers/anime)
#   PRIMARY_OUTPUT  (default: DP-3) — gets symlinked from ~/.config/background
#   DURATION        awww --transition-duration (default 1.5)
#   TRANSITION      awww --transition-type     (default fade)

set -euo pipefail

WP_DIR="${WP_DIR:-$HOME/Pictures/Wallpapers/anime}"
PRIMARY_OUTPUT="${PRIMARY_OUTPUT:-DP-3}"
DURATION="${DURATION:-1.5}"
TRANSITION="${TRANSITION:-fade}"

mapfile -t outputs < <(hyprctl monitors -j | jq -r '.[].name')
n="${#outputs[@]}"
(( n > 0 )) || { echo "no outputs" >&2; exit 1; }

mapfile -t picks < <(
    find "$WP_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
        2>/dev/null | shuf -n "$n"
)
(( ${#picks[@]} >= n )) || { echo "need $n images in $WP_DIR, have ${#picks[@]}" >&2; exit 1; }

# Issue all awww calls in parallel and wait. awww-daemon arbitrates per-output
# state itself; no sleep races to manage.
pids=()
primary_img=""
for i in "${!outputs[@]}"; do
    out="${outputs[$i]}"
    img="${picks[$i]}"
    awww img -o "$out" "$img" \
        --transition-type "$TRANSITION" \
        --transition-duration "$DURATION" \
        --transition-fps 60 &
    pids+=("$!")
    [[ "$out" == "$PRIMARY_OUTPUT" ]] && primary_img="$img"
done
wait "${pids[@]}"

# Keep ~/.config/background pointing at the primary monitor's image.
[[ -n "$primary_img" ]] && ln -sfT "$primary_img" "$HOME/.config/background"
