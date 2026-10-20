#!/bin/bash
# Links each config folder in this repo into ~/.config, so editing the repo
# edits the live desktop. Anything already there is moved aside first.
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.config"
for dir in labwc quickshell ghostty fontconfig gtk-3.0; do
  target="$HOME/.config/$dir"
  if [[ -e $target && ! -L $target ]]; then
    mv "$target" "$target.bak.$(date +%s)"
  fi
  ln -sfn "$repo/$dir" "$target"
done

# The theme: labwc's title bars and window buttons, and GTK apps.
mkdir -p "$HOME/.local/share/themes"
ln -sfn "$repo/theme" "$HOME/.local/share/themes/puter"

# The icon theme: line icons for places and files.
mkdir -p "$HOME/.local/share/icons"
ln -sfn "$repo/theme/icons" "$HOME/.local/share/icons/puter"

# GTK on Wayland reads its theme from gsettings rather than settings.ini.
if command -v gsettings >/dev/null; then
  gsettings set org.gnome.desktop.interface gtk-theme puter
  gsettings set org.gnome.desktop.interface icon-theme puter
  gsettings set org.gnome.desktop.interface font-name "Geist 11"
  gsettings set org.gnome.desktop.interface enable-animations false
  gsettings set org.gnome.desktop.interface font-antialiasing grayscale
fi

# Thunar: the sidebar six modules wide, so the file view starts on the grid,
# and its icons at 16px, the size they are drawn for.
if command -v xfconf-query >/dev/null; then
  xfconf-query -c thunar -p /last-separator-position -n -t int -s 180
  xfconf-query -c thunar -p /shortcuts-icon-size -n -t string -s THUNAR_ICON_SIZE_16
  xfconf-query -c thunar -p /tree-icon-size -n -t string -s THUNAR_ICON_SIZE_16
fi
