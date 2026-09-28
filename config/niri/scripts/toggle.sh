#!/usr/bin/env bash
# Session-only overrides that config.kdl includes from $XDG_RUNTIME_DIR, so they reset at logout like hyprctl keywords did.
set -euo pipefail

name=${1:?usage: $0 <animations|gamemode>}
dir="$XDG_RUNTIME_DIR/niri"
file="$dir/$name.kdl"
mkdir -p "$dir"

if [ -s "$file" ]; then
  : >"$file"
  if [ "$name" = gamemode ]; then
    notify-send "Gamemode deactivated" "Animations and blur enabled"
  fi
  exit 0
fi

case $name in
  animations)
    echo 'animations { off; }' >"$file"
    ;;
  gamemode)
    cat >"$file" <<'EOF'
animations { off; }
blur { off; }
layout {
    gaps 0
    border { width 1; }
    shadow { off; }
}
window-rule {
    geometry-corner-radius 0
}
EOF
    notify-send "Gamemode activated" "Animations and blur disabled"
    ;;
  *)
    echo "unknown toggle: $name" >&2
    exit 1
    ;;
esac
