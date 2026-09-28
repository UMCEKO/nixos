#!/usr/bin/env bash
# niri stand-ins for Hyprland's moveTo.sh and the per-workspace float toggle.
set -euo pipefail

focused_id() { niri msg -j workspaces | jq '.[] | select(.is_focused) | .id'; }
windows_here() { niri msg -j windows | jq --argjson ws "$(focused_id)" '.[] | select(.workspace_id == $ws) | .id'; }

case ${1:-} in
  move-all)
    target=${2:?usage: $0 move-all <workspace index>}
    for id in $(windows_here); do
      niri msg action move-window-to-workspace --window-id "$id" --focus false "$target"
    done
    niri msg action focus-workspace "$target"
    ;;
  float-all)
    for id in $(windows_here); do
      niri msg action toggle-window-floating --id "$id"
    done
    ;;
  *)
    echo "usage: $0 move-all <index> | float-all" >&2
    exit 1
    ;;
esac
