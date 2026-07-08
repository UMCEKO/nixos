#!/usr/bin/env bash
# Per-monitor workspace switcher (rewritten 2026-07-08 for NixOS + Hyprland 0.55).
#
# Maps input 1-10 onto the workspace range of the FOCUSED monitor, using
# Hyprland's live workspace->monitor bindings as the source of truth
# (defined in lua/workspaces.lua: DP-3 = 1-10, DP-4 = 11-20).
# The old version derived monitor IDs from alphabetically-sorted display
# names, which disagreed with the actual rules and switched the wrong monitor.
#
# Usage: switch-workspace.sh <workspace|movetoworkspace|movetoworkspacesilent> <1-10>

set -euo pipefail

command=${1:?usage: $0 <command> <1-10>}
input=${2:?usage: $0 <command> <1-10>}

[[ "$input" =~ ^[1-9]$|^10$ ]] || { echo "workspace must be 1-10"; exit 1; }
case "$command" in
  workspace|movetoworkspace|movetoworkspacesilent) ;;
  *) echo "command must be workspace|movetoworkspace|movetoworkspacesilent"; exit 1 ;;
esac

# Focused monitor's port name (fall back to the active window's monitor).
mon=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
[ -z "$mon" ] && mon=$(hyprctl activewindow -j | jq -r '.monitor // empty')
[ -z "$mon" ] && { echo "no focused monitor"; exit 1; }

# Base = lowest workspace id bound to that monitor (from live state).
base=$(hyprctl workspaces -j | jq --arg m "$mon" '[.[] | select(.monitor == $m) | .id | select(. > 0)] | min')
[ "$base" = "null" ] && base=1

target=$((base + input - 1))

# Hyprland 0.55 lua config manager: dispatch takes hl.dsp.* expressions.
case "$command" in
  workspace)             hyprctl dispatch "hl.dsp.focus({ workspace = $target })" ;;
  movetoworkspace)       hyprctl dispatch "hl.dsp.window.move({ workspace = $target })" ;;
  movetoworkspacesilent) hyprctl dispatch "hl.dsp.window.move({ workspace = $target, silent = true })" ;;
esac
echo "$command: monitor=$mon base=$base input=$input -> $target"
