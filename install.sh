#!/bin/bash
# Links each config folder in this repo into ~/.config, so editing the repo
# edits the live desktop. Anything already there is moved aside first.
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.config"
for dir in labwc quickshell ghostty fontconfig; do
  target="$HOME/.config/$dir"
  if [[ -e $target && ! -L $target ]]; then
    mv "$target" "$target.bak.$(date +%s)"
  fi
  ln -sfn "$repo/$dir" "$target"
done

# The labwc theme: title bar colours and the window buttons.
mkdir -p "$HOME/.local/share/themes"
ln -sfn "$repo/theme" "$HOME/.local/share/themes/puter"
