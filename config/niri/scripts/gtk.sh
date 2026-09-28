#!/usr/bin/env bash
# Mirrors gtk-3.0/settings.ini into gsettings (hypr/scripts/gtk.sh minus hyprctl; niri's cursor block sets the cursor).
config="$HOME/.config/gtk-3.0/settings.ini"
[ -f "$config" ] || exit 1

get() { grep "$1" "$config" | sed 's/.*\s*=\s*//'; }

schema="org.gnome.desktop.interface"
gsettings set "$schema" gtk-theme "$(get gtk-theme-name)"
gsettings set "$schema" icon-theme "$(get gtk-icon-theme-name)"
gsettings set "$schema" cursor-theme "$(get gtk-cursor-theme-name)"
gsettings set "$schema" font-name "$(get gtk-font-name)"
if [ "$(get gtk-application-prefer-dark-theme)" = "0" ]; then
  gsettings set "$schema" color-scheme prefer-light
else
  gsettings set "$schema" color-scheme prefer-dark
fi

terminal_schema="com.github.stunkymonkey.nautilus-open-any-terminal"
gsettings set "$terminal_schema" terminal "$(cat "$HOME/.config/ml4w/settings/terminal.sh")"
gsettings set "$terminal_schema" use-generic-terminal-name "true"
gsettings set "$terminal_schema" keybindings "<Ctrl><Alt>t"
