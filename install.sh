#!/bin/bash
# Installs puter on a plain Arch install (archinstall, minimal profile, a user
# with sudo). Safe to run again.
#
#   ./install.sh          everything: packages, fonts, configs, login screen
#   ./install.sh config   only link the configs and apply settings (what
#                         dev/sync runs after copying a change over)
#   ./install.sh packages only install the packages and Geist
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"

packages() {
  mapfile -t pkgs < <(sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$repo/packages.txt" | grep -v '^$')
  sudo pacman -Syu --needed --noconfirm "${pkgs[@]}"

  # Geist is only in the AUR; it is built straight with makepkg.
  if ! pacman -Q otf-geist >/dev/null 2>&1; then
    build="$(mktemp -d)"
    git clone --depth 1 https://aur.archlinux.org/geist-font.git "$build"
    (cd "$build" && makepkg -s --noconfirm && sudo pacman -U --noconfirm otf-geist-[0-9]*.pkg.tar.zst)
    rm -rf "$build"
  fi

  # Thunar, patched so its path field sits on the grid (packages/thunar).
  # Rebuilt whenever the installed version isn't the recipe's.
  local want have
  # shellcheck disable=SC2154  # pkgver and pkgrel come from the PKGBUILD
  want="$(source "$repo/packages/thunar/PKGBUILD" && echo "$pkgver-$pkgrel")"
  have="$(pacman -Q thunar 2>/dev/null | cut -d' ' -f2)"
  if [[ $have != "$want" ]]; then
    build="$(mktemp -d)"
    cp "$repo/packages/thunar/PKGBUILD" "$build/"
    (cd "$build" && makepkg -s --noconfirm && sudo pacman -U --noconfirm thunar-[0-9]*.pkg.tar.zst)
    rm -rf "$build"
  fi
}

# Runs a command on the session bus, starting a private one when there is no
# desktop session yet (a first install from the console).
on_bus() {
  if [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then "$@"; else dbus-run-session -- "$@"; fi
}

settings() {
  # GTK on Wayland reads its theme from gsettings rather than settings.ini.
  gsettings set org.gnome.desktop.interface gtk-theme puter
  gsettings set org.gnome.desktop.interface icon-theme puter
  gsettings set org.gnome.desktop.interface font-name "Geist 11"
  gsettings set org.gnome.desktop.interface enable-animations false
  gsettings set org.gnome.desktop.interface font-antialiasing grayscale

  # Mousepad: puter's colours, Geist Mono, line numbers, spaces for tabs.
  local m=org.xfce.mousepad.preferences.view
  gsettings set $m color-scheme puter
  gsettings set $m use-default-monospace-font false
  gsettings set $m font-name "GeistMono Nerd Font 11"
  gsettings set $m show-line-numbers true
  gsettings set $m highlight-current-line false
  gsettings set $m insert-spaces true
  gsettings set $m tab-width 4

  # Thunar.
  local t=(xfconf-query -c thunar -n -p)
  # No side pane (F9 shows it): the Places pane pads its headings 4px more than
  # its rows in code, and the tree pane's rows vary, so neither keeps to the
  # grid. The list view does: one module per file.
  "${t[@]}" /last-side-pane -t string -s void
  "${t[@]}" /default-view -t string -s ThunarDetailsView
  "${t[@]}" /last-view -t string -s ThunarDetailsView
  "${t[@]}" /last-separator-position -t int -s 180
  "${t[@]}" /shortcuts-icon-size -t string -s THUNAR_ICON_SIZE_16
  "${t[@]}" /tree-icon-size -t string -s THUNAR_ICON_SIZE_16
  # 24px icons in the list, the size they are drawn for.
  "${t[@]}" /last-details-view-zoom-level -t string -s THUNAR_ZOOM_LEVEL_38_PERCENT
  # Toolbar icons from puter's icon theme as drawn, not GTK's symbolic ones,
  # which GTK fills in solid.
  "${t[@]}" /misc-symbolic-icons-in-toolbar -t bool -s false
  # The toolbar: back, home, the path field and search.
  "${t[@]}" /last-toolbar-items -t string -s "menu:0,back:1,forward:0,open-parent:0,open-home:1,new-tab:0,new-window:0,toggle-split-view:0,undo:0,redo:0,zoom-out:0,zoom-in:0,zoom-reset:0,view-as-icons:0,view-as-detailed-list:0,view-as-compact-list:0,view-switcher:0,location-bar:1,reload:0,search:1"
}

config() {
  # Each config folder is linked into ~/.config, so editing the repo edits the
  # live desktop. Anything already there is moved aside first.
  mkdir -p "$HOME/.config"
  for dir in labwc quickshell ghostty fontconfig gtk-3.0 imv mpv; do
    target="$HOME/.config/$dir"
    if [[ -e $target && ! -L $target ]]; then
      mv "$target" "$target.bak.$(date +%s)"
    fi
    ln -sfn "$repo/$dir" "$target"
  done

  # The theme: labwc's title bars and window buttons, and GTK apps; and the
  # icon theme.
  mkdir -p "$HOME/.local/share/themes" "$HOME/.local/share/icons"
  ln -sfn "$repo/theme" "$HOME/.local/share/themes/puter"
  ln -sfn "$repo/theme/icons" "$HOME/.local/share/icons/puter"
  mkdir -p "$HOME/.local/share/gtksourceview-4/styles"
  ln -sfn "$repo/theme/gtksourceview/puter.xml" "$HOME/.local/share/gtksourceview-4/styles/puter.xml"

  # Which app opens what.
  ln -sfn "$repo/mimeapps.list" "$HOME/.config/mimeapps.list"

  on_bus bash -c "$(declare -f settings); settings"
}

login() {
  # greetd with tuigreet: a text login screen that starts labwc.
  sudo tee /etc/greetd/config.toml >/dev/null <<'TOML'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --asterisks --cmd labwc"
user = "greeter"
TOML
  sudo systemctl enable greetd.service NetworkManager.service
}

case "${1:-all}" in
  config)
    config
    ;;
  packages)
    packages
    ;;
  all)
    packages
    config
    login
    echo "Done. Reboot to log in to puter."
    ;;
  *)
    echo "usage: $0 [config|packages]" >&2
    exit 1
    ;;
esac
