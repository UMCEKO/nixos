#!/bin/bash

# Hyprland Monitor Profile Switcher
# Toggles between monitor profiles in ~/.config/hypr/conf/monitors/
# Creates symlink to ~/.config/hypr/conf/monitor.conf

set -euo pipefail

# Configuration
PROFILES_DIR="$HOME/.config/hypr/conf/monitors"
SYMLINK_TARGET="$HOME/.config/hypr/conf/monitor.conf"
STATE_FILE="$HOME/.cache/hypr_monitor_profile"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_msg() {
  local color=$1
  local message=$2
  echo -e "${color}${message}${NC}"
}

# Function to show usage
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help       Show this help message"
  echo "  -l, --list       List available monitor profiles"
  echo "  -c, --current    Show current active profile"
  echo "  --no-reload      Don't reload Hyprland after switching (reload is default)"
  echo ""
  echo "Monitor profiles should be placed in: $PROFILES_DIR"
  echo "Active profile will be symlinked to: $SYMLINK_TARGET"
}

# Function to list available profiles
list_profiles() {
  if [[ ! -d "$PROFILES_DIR" ]]; then
    print_msg "$RED" "Error: Profiles directory does not exist: $PROFILES_DIR"
    return 1
  fi

  local profiles=($(find "$PROFILES_DIR" -name "*.conf" -type f -printf "%f\n" | sort))

  if [[ ${#profiles[@]} -eq 0 ]]; then
    print_msg "$YELLOW" "No monitor profiles found in $PROFILES_DIR"
    return 1
  fi

  print_msg "$BLUE" "Available monitor profiles:"
  for i in "${!profiles[@]}"; do
    echo "  $((i + 1)). ${profiles[i]}"
  done
}

# Function to get current active profile
get_current_profile() {
  if [[ -L "$SYMLINK_TARGET" ]]; then
    local target=$(readlink "$SYMLINK_TARGET")
    local profile_name=$(basename "$target")
    echo "$profile_name"
  else
    echo "none"
  fi
}

# Function to show current profile
show_current() {
  local current=$(get_current_profile)
  if [[ "$current" == "none" ]]; then
    print_msg "$YELLOW" "No active monitor profile"
  else
    print_msg "$GREEN" "Current active profile: $current"
  fi
}

# Function to create directories if they don't exist
ensure_directories() {
  mkdir -p "$PROFILES_DIR"
  mkdir -p "$(dirname "$SYMLINK_TARGET")"
  mkdir -p "$(dirname "$STATE_FILE")"
}

# Function to reload Hyprland configuration
reload_hyprland() {
  if command -v hyprctl >/dev/null 2>&1; then
    print_msg "$BLUE" "Reloading Hyprland configuration..."
    hyprctl reload
    print_msg "$GREEN" "Hyprland configuration reloaded"
  else
    print_msg "$YELLOW" "hyprctl not found - please reload Hyprland manually"
  fi
}

# Function to switch to next profile
switch_profile() {
  local reload_after=true # Default to true since symlinks need reload

  # Check if reload flag is explicitly disabled
  for arg in "$@"; do
    if [[ "$arg" == "--no-reload" ]]; then
      reload_after=false
      break
    fi
  done

  ensure_directories

  # Get available profiles
  local profiles=($(find "$PROFILES_DIR" -name "*.conf" -type f -printf "%f\n" | sort))

  if [[ ${#profiles[@]} -eq 0 ]]; then
    print_msg "$RED" "Error: No monitor profiles found in $PROFILES_DIR"
    print_msg "$YELLOW" "Create some .conf files in that directory first"
    return 1
  fi

  # Read current index from state file, default to -1 (so first run goes to index 0)
  local current_index=-1
  if [[ -f "$STATE_FILE" ]]; then
    current_index=$(cat "$STATE_FILE" 2>/dev/null || echo "-1")
  fi

  # Calculate next index with rollover
  local next_index=$(((current_index + 1) % ${#profiles[@]}))
  local next_profile="${profiles[$next_index]}"
  local profile_path="$PROFILES_DIR/$next_profile"

  # Remove existing symlink if it exists
  if [[ -L "$SYMLINK_TARGET" || -f "$SYMLINK_TARGET" ]]; then
    rm "$SYMLINK_TARGET"
  fi

  # Create new symlink
  ln -s "$profile_path" "$SYMLINK_TARGET"

  # Save current index to state file
  echo "$next_index" >"$STATE_FILE"

  print_msg "$GREEN" "Switched to monitor profile: $next_profile"
  print_msg "$BLUE" "Profile $((next_index + 1)) of ${#profiles[@]}"

  # Reload Hyprland if requested
  if [[ "$reload_after" == true ]]; then
    reload_hyprland
  fi
}

# Main script logic
main() {
  # Handle command line arguments
  case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  -l | --list)
    list_profiles
    exit 0
    ;;
  -c | --current)
    show_current
    exit 0
    ;;
  --no-reload)
    switch_profile "$@"
    exit 0
    ;;
  "")
    switch_profile
    exit 0
    ;;
  *)
    print_msg "$RED" "Unknown option: $1"
    usage
    exit 1
    ;;
  esac
}

# Run main function with all arguments
main "$@"
