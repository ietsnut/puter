#!/bin/bash
# Installs puter on a plain Arch install (archinstall, minimal profile, a user
# with sudo). Safe to run again.
#
#   ./install.sh          everything: packages, fonts, configs, login screen
#   ./install.sh config   only link the configs and apply settings (what
#                         dev/sync runs after copying a change over)
#   ./install.sh packages only install the packages
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"

packages() {
  mapfile -t pkgs < <(sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$repo/packages.txt" | grep -v '^$')
  sudo pacman -Syu --needed --noconfirm "${pkgs[@]}"

  # labwc, patched, and JLCONE (packages/). Each is
  # rebuilt whenever the installed version isn't its recipe's.
  local name want have
  for name in labwc jlcone-bin; do
    # shellcheck disable=SC2154  # pkgver and pkgrel come from the PKGBUILD
    want="$(source "$repo/packages/$name/PKGBUILD" && echo "$pkgver-$pkgrel")"
    # Empty when it isn't installed yet (pacman -Q fails, which would end the
    # script under pipefail).
    have="$(pacman -Q "$name" 2>/dev/null | cut -d' ' -f2 || true)"
    if [[ $have != "$want" ]]; then
      build="$(mktemp -d)"
      cp "$repo/packages/$name/"* "$build/"
      (cd "$build" && makepkg -s --noconfirm && sudo pacman -U --noconfirm "$name"-[0-9]*.pkg.tar.zst)
      rm -rf "$build"
    fi
  done

  # puter's Qt widget style and its table editor, Sheet, built from src/.
  for part in style sheet; do
    build="$(mktemp -d)"
    cmake -S "$repo/src/$part" -B "$build" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
    cmake --build "$build"
    sudo cmake --install "$build"
    rm -rf "$build"
  done
}

# Sets one key in an ini file (Qt's settings files), making the file and the
# section if need be:  ini FILE SECTION KEY VALUE
ini() {
  mkdir -p "$(dirname "$1")"
  python3 - "$@" <<'PY'
import pathlib, sys
path, section, key, value = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
lines = path.read_text().splitlines() if path.exists() else []
out, here, done = [], False, False
for line in lines:
    if line.startswith("["):
        if here and not done:
            out.append(f"{key}={value}")
            done = True
        here = line.strip() == f"[{section}]"
    elif here and line.split("=", 1)[0] == key:
        line, done = f"{key}={value}", True
    out.append(line)
if not done:
    if not here:
        out.append(f"[{section}]")
    out.append(f"{key}={value}")
path.write_text("\n".join(out) + "\n")
PY
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
  gsettings set org.gnome.desktop.interface font-name "puter-sans 11"
  gsettings set org.gnome.desktop.interface enable-animations false
  gsettings set org.gnome.desktop.interface font-antialiasing grayscale
}

config() {
  # Each config folder is linked into ~/.config, so editing the repo edits the
  # live desktop. Anything already there is moved aside first.
  mkdir -p "$HOME/.config"
  for dir in labwc quickshell fontconfig gtk-3.0 xdg-desktop-portal; do
    target="$HOME/.config/$dir"
    if [[ -e $target && ! -L $target ]]; then
      mv "$target" "$target.bak.$(date +%s)"
    fi
    ln -sfn "$repo/config/$dir" "$target"
  done

  # The file dialog's portal takes puter's Qt style (config/systemd/). Only its
  # drop-in folder is linked: ~/.config/systemd/user also holds what
  # systemctl --user enable writes.
  mkdir -p "$HOME/.config/systemd/user"
  ln -sfn "$repo/config/systemd/user/xdg-desktop-portal-lxqt.service.d" "$HOME/.config/systemd/user/xdg-desktop-portal-lxqt.service.d"
  if [[ -n ${XDG_RUNTIME_DIR:-} ]]; then
    systemctl --user daemon-reload 2>/dev/null || true
  fi

  # Fonts the repos don't have (theme/fonts: Stack Sans, SIL OFL), for the
  # palettes that use them.
  mkdir -p "$HOME/.local/share/fonts"
  ln -sfn "$repo/theme/fonts" "$HOME/.local/share/fonts/puter"
  fc-cache -f >/dev/null 2>&1 || true

  # The theme: labwc's title bars and window buttons, and GTK apps; and the
  # icon theme.
  mkdir -p "$HOME/.local/share/themes" "$HOME/.local/share/icons"
  ln -sfn "$repo/theme" "$HOME/.local/share/themes/puter"
  ln -sfn "$repo/theme/icons" "$HOME/.local/share/icons/puter"

  # KiCad's colours: the theme, chosen in every editor. Copied rather than
  # linked, since KiCad saves its themes back to this folder.
  if command -v kicad >/dev/null; then
    kicad_config="$HOME/.config/kicad/10.0"
    mkdir -p "$kicad_config/colors"
    cp "$repo/theme/kicad/puter.json" "$kicad_config/colors/puter.json"
    python3 - "$kicad_config" <<'PY'
import json, pathlib, sys
config = pathlib.Path(sys.argv[1])
for app in ("pcbnew", "eeschema", "fpedit", "symbol_editor", "gerbview"):
    path = config / f"{app}.json"
    settings = json.loads(path.read_text()) if path.exists() else {}
    settings.setdefault("appearance", {})["color_theme"] = "puter"
    path.write_text(json.dumps(settings, indent=2))
PY
  fi

  # Qt Widgets apps: puter's widget style (src/style), palette, fonts and
  # stylesheet, and file dialogs from the portal (the same libfm-qt dialog
  # every other app gets, xdg-desktop-portal/), through qt6ct
  # (QT_QPA_PLATFORMTHEME in config/labwc/environment). Written here rather than
  # kept in the repo because qt6ct wants absolute paths.
  mkdir -p "$HOME/.config/qt6ct"
  cat > "$HOME/.config/qt6ct/qt6ct.conf" <<CONF
[Appearance]
style=puter
custom_palette=true
color_scheme_path=$repo/theme/qt6ct/puter.conf
icon_theme=puter
standard_dialogs=xdgdesktopportal

[Fonts]
general="puter-sans,-1,15,5,400,0,0,0,0,0,0,0,0,0,0,1"
fixed="puter-mono,-1,14,5,400,0,0,0,0,0,0,0,0,0,0,1"

[Interface]
menus_have_icons=false
show_shortcuts_in_context_menus=true
toolbutton_style=0
dialog_buttons_have_icons=0
activate_item_on_single_click=0
stylesheets=$HOME/.config/qt6ct/puter.qss
CONF
  # The stylesheet, with the icon theme's path filled in (Qt needs it whole).
  sed "s|@icons|$HOME/.local/share/icons/puter|g" "$repo/theme/qt6ct/puter.qss" > "$HOME/.config/qt6ct/puter.qss"

  # FeatherPad: system icons, puter-mono, puter's syntax colours, the
  # search bar only when searching, no toolbar, status bar or tab strip for a
  # single file; no line numbers, since it paints their gutter dark gray in
  # code.
  ini "$HOME/.config/featherpad/fp.conf" text font '"puter-mono,10.5,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"'
  ini "$HOME/.config/featherpad/fp.conf" text lineNumbers false
  ini "$HOME/.config/featherpad/fp.conf" window sysIcons true
  ini "$HOME/.config/featherpad/fp.conf" window hideSearchbar true
  ini "$HOME/.config/featherpad/fp.conf" window noToolbar true
  ini "$HOME/.config/featherpad/fp.conf" window showStatusbar false
  ini "$HOME/.config/featherpad/fp.conf" window hideSingleTab true
  ln -sfn "$repo/theme/featherpad/fp_light_syntax_colors.conf" "$HOME/.config/featherpad/fp_light_syntax_colors.conf"
  # PCManFM-Qt: the list view with 16px icons, one module per file, showing
  # only name, size and date; no side pane (Go has the places), no tab strip
  # for a single folder, no close buttons on tabs.
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" FolderView Mode detailed
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" FolderView HiddenColumns "1, 4, 5, 6, 7, 8"
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" Window SidePaneVisible false
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" Window AlwaysShowTabs false
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" Window ShowTabClose false
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" FolderView SmallIconSize 16
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" FolderView SidePaneIconSize 16

  # The file dialog (libfm-qt's, every app's through the portal): the list
  # view as in PCManFM-Qt, 16px icons, only name, size and date, no
  # thumbnails or tooltips, 24 x 16 modules. src/style lays out the rest.
  local d="$HOME/.config/lxqt/filedialog.conf"
  ini "$d" Sizes WindowSize "@Size(720 480)"
  ini "$d" View Mode Detailed
  ini "$d" View SmallIconSize 16
  ini "$d" View HiddenColumns "1, 4, 5, 6, 7"
  ini "$d" View ShowThumbnails false
  ini "$d" View NoItemTooltip true

  # Falkon: back, forward, reload and the address field (which also searches)
  # and nothing else; the menu bar, as in every other app, instead of the
  # tools button; blank pages at start and in new tabs, no session restored.
  local f="$HOME/.config/falkon/profiles/default/settings.ini"
  ini "$f" NavigationBar Layout "button-backforward, button-reloadstop, locationbar"
  ini "$f" NavigationBar ShowSearchBar false
  ini "$f" Browser-View-Settings showMenubar true
  ini "$f" Browser-View-Settings showStatusBar false
  ini "$f" Browser-View-Settings showBookmarksToolbar false
  ini "$f" Web-URL-Settings afterLaunch 0
  ini "$f" Web-URL-Settings homepage about:blank
  ini "$f" Web-URL-Settings newTabUrl about:blank

  # QTerminal: puter's colours (theme/qterminal/, from theme/make), puter-mono,
  # no margin (nor the 2px it keeps around a terminal to outline the focused
  # one of a split), the tab bar only with more than one tab.
  mkdir -p "$HOME/.local/share/qtermwidget6/color-schemes"
  ln -sfn "$repo/theme/qterminal/puter.colorscheme" "$HOME/.local/share/qtermwidget6/color-schemes/puter.colorscheme"
  local q="$HOME/.config/qterminal.org/qterminal.ini"
  ini "$q" General colorScheme puter
  ini "$q" General fontFamily "puter-mono"
  ini "$q" General fontSize 11
  ini "$q" General TerminalMargin 0
  ini "$q" General highlightCurrentTerminal false
  ini "$q" General HideTabBarWithOneTab true
  ini "$q" General AskOnExit false
  ini "$q" General MenuVisible true

  # Which app opens what.
  ln -sfn "$repo/config/mimeapps.list" "$HOME/.config/mimeapps.list"

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
