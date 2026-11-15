#!/bin/bash
# Installs puter on a plain Arch install (archinstall, minimal profile, a user
# with sudo). Safe to run again.
#
#   ./install.sh          everything: packages, fonts, configs, no passwords,
#                         straight into the desktop on boot
#   ./install.sh config   only link the configs and apply settings (after
#                         changing them)
#   ./install.sh packages only the packages, builds and settings (as an update)
#   ./install.sh access   only stop sudo and polkit asking for a password,
#                         and let config/ssh/authorized_keys in over SSH
#   ./install.sh remote   only that SSH (puter.local, by key)
#   ./install.sh login    only start straight into the desktop on boot (what
#                         the USB installer runs, iso/, beside access and
#                         config, having installed the packages itself)
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"

# The packages (Arch's, and puter's own from its repository, [puter]) and
# Claude Code, then the settings: bin/puter-update does all of it, so a first
# install is an update from nothing.
packages() {
  sudo "$repo/bin/puter-update" run
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

# The folder of the Firefox (or Thunderbird) profile this install opens,
# from its profiles.ini: the [Install...] section's Default, else the
# default profile.
firefox_profile() {
  python3 - "$1" <<'PROFILE'
import configparser, sys
ini = configparser.ConfigParser()
ini.read(sys.argv[1])
install = [s for s in ini.sections() if s.startswith("Install") and ini[s].get("Default")]
default = [s for s in ini.sections() if ini[s].get("Default") == "1" and ini[s].get("Path")]
print(ini[install[0]]["Default"] if install else ini[default[0]]["Path"] if default else "")
PROFILE
}

# Runs a command on the session bus, starting a private one when there is no
# desktop session yet (a first install from the console).
on_bus() {
  if [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then "$@"; else dbus-run-session -- "$@"; fi
}

# A Mozilla profile's user.js: puter's prefs, then its pages, toolbars and
# windows dark or light as the palette is (theme/mode; 0 is dark, 1 light).
mozilla_prefs() { # prefs profile/user.js
  local scheme=1
  [[ $(cat "$repo/theme/mode") == dark ]] && scheme=0
  rm -f "$2"
  {
    cat "$1"
    echo
    echo "// Written by install.sh config from theme/mode."
    echo "user_pref(\"layout.css.prefers-color-scheme.content-override\", $scheme);"
    echo "user_pref(\"browser.theme.toolbar-theme\", $scheme);"
    echo "user_pref(\"browser.theme.content-theme\", $scheme);"
  } >"$2"
}

settings() {
  # GTK on Wayland reads its theme from gsettings rather than settings.ini.
  gsettings set org.gnome.desktop.interface gtk-theme puter
  gsettings set org.gnome.desktop.interface icon-theme puter
  # Dark or light as the palette is (theme/mode), for the apps that ask
  # (GTK 4, portals).
  if [[ $(cat "$repo/theme/mode") == dark ]]; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
  else
    gsettings set org.gnome.desktop.interface color-scheme default
  fi
  gsettings set org.gnome.desktop.interface font-name "puter-sans 11"
  gsettings set org.gnome.desktop.interface enable-animations false
  gsettings set org.gnome.desktop.interface font-antialiasing grayscale
}

config() {
  # Each config folder is linked into ~/.config, so editing the repo edits the
  # live desktop. Anything already there is moved aside first.
  mkdir -p "$HOME/.config"
  # The desk shows ~/Desktop (config/quickshell/Desk.qml).
  mkdir -p "$HOME/Desktop"
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

  # git signs in to GitHub through gh, once `gh auth login` has been run (the
  # token stays in ~/.config/gh, never in the repo).
  git config --global --replace-all credential.https://github.com.helper ''
  git config --global --add credential.https://github.com.helper '!/usr/bin/gh auth git-credential'
  git config --global --replace-all credential.https://gist.github.com.helper ''
  git config --global --add credential.https://gist.github.com.helper '!/usr/bin/gh auth git-credential'
  # and commits as that GitHub account, at its private noreply address.
  if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
    local gh_user gh_id gh_login gh_name
    if gh_user="$(gh api user --jq '"\(.id) \(.login) \(.name // .login)"' 2>/dev/null)"; then
      read -r gh_id gh_login gh_name <<<"$gh_user"
      git config --global user.name "$gh_name"
      git config --global user.email "$gh_id+$gh_login@users.noreply.github.com"
    fi
  fi

  # The agents' terminal, foot: its settings and colours (theme/foot, from
  # theme/make).
  ln -sfn "$repo/theme/foot" "$HOME/.config/foot"

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
fixed="puter-mono,-1,15,5,400,0,0,0,0,0,0,0,0,0,0,1"

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
  # code. Every app opens at 24 x 18 modules rather than at the size it last
  # had (which is seldom on the grid).
  # Its folder is read-only once these are in: FeatherPad writes all its
  # settings back as it quits (by replacing the file, so only the folder can
  # stop it), and an open one would put back what it started with.
  mkdir -p "$HOME/.config/featherpad"
  chmod u+w "$HOME/.config/featherpad"
  ini "$HOME/.config/featherpad/fp.conf" text font '"puter-mono,-1,15,5,400,0,0,0,0,0,0,0,0,0,0,1"'
  ini "$HOME/.config/featherpad/fp.conf" text lineNumbers false
  ini "$HOME/.config/featherpad/fp.conf" window sysIcons true
  ini "$HOME/.config/featherpad/fp.conf" window hideSearchbar true
  ini "$HOME/.config/featherpad/fp.conf" window noToolbar true
  ini "$HOME/.config/featherpad/fp.conf" window showStatusbar false
  ini "$HOME/.config/featherpad/fp.conf" window hideSingleTab true
  ini "$HOME/.config/featherpad/fp.conf" window size none
  ini "$HOME/.config/featherpad/fp.conf" window startSize "@Size(720 540)"
  # Its syntax colours a copy, not a link: it writes them back as it quits
  # (into this checkout, were they a link).
  rm -f "$HOME/.config/featherpad/fp_light_syntax_colors.conf"
  cp "$repo/theme/featherpad/fp_light_syntax_colors.conf" "$HOME/.config/featherpad/"
  chmod a-w "$HOME/.config/featherpad"
  # PCManFM-Qt: the list view with 16px icons, one module per file, showing
  # only name, size and date; no side pane (Go has the places), no tab strip
  # for a single folder, no close buttons on tabs; 24 x 18 modules.
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" FolderView Mode detailed
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" FolderView HiddenColumns "1, 4, 5, 6, 7, 8"
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" Window SidePaneVisible false
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" Window AlwaysShowTabs false
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" Window ShowTabClose false
  # Its toolbar (src/style): back, the folder's whole path as text rather
  # than a button per folder, and a terminal there (QTerminal).
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" Window PathBarButtons false
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" System Terminal qterminal
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" FolderView SmallIconSize 16
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" FolderView SidePaneIconSize 16
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" Window RememberWindowSize false
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" Window FixedWidth 720
  ini "$HOME/.config/pcmanfm-qt/default/settings.conf" Window FixedHeight 540

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

  # Firefox: its settings (config/firefox/user.js) and puter's stylesheet
  # (theme/firefox/chrome, from theme/make) in its default profile, which a
  # first run with no window makes if there's none yet.
  if command -v firefox >/dev/null; then
    local ff="$HOME/.config/mozilla/firefox" profile
    [[ -f $ff/profiles.ini ]] || timeout 30 firefox --headless about:blank >/dev/null 2>&1 || true
    profile="$(firefox_profile "$ff/profiles.ini")"
    if [[ -n $profile && -d $ff/$profile ]]; then
      mozilla_prefs "$repo/config/firefox/user.js" "$ff/$profile/user.js"
      ln -sfn "$repo/theme/firefox/chrome" "$ff/$profile/chrome"
    fi
  fi

  # Thunderbird, the same way (config/thunderbird/user.js and
  # theme/thunderbird/chrome); its profile is in ~/.config/thunderbird.
  if command -v thunderbird >/dev/null; then
    local tb="$HOME/.config/thunderbird"
    [[ -f $tb/profiles.ini ]] || timeout 30 thunderbird --headless >/dev/null 2>&1 || true
    profile="$(firefox_profile "$tb/profiles.ini")"
    if [[ -n $profile && -d $tb/$profile ]]; then
      mozilla_prefs "$repo/config/thunderbird/user.js" "$tb/$profile/user.js"
      ln -sfn "$repo/theme/thunderbird/chrome" "$tb/$profile/chrome"
    fi
  fi

  # QTerminal: puter's colours (theme/qterminal/, from theme/make), puter-mono,
  # no margin (nor the 2px it keeps around a terminal to outline the focused
  # one of a split), the tab bar only with more than one tab; 24 x 18 modules.
  # Its own schemes are read from ~/.local/share/qterminal/color-schemes
  # (qtermwidget6's folder there isn't, so the link once made there goes).
  rm -f "$HOME/.local/share/qtermwidget6/color-schemes/puter.colorscheme"
  rmdir -p "$HOME/.local/share/qtermwidget6/color-schemes" 2>/dev/null || true
  mkdir -p "$HOME/.local/share/qterminal/color-schemes"
  ln -sfn "$repo/theme/qterminal/puter.colorscheme" "$HOME/.local/share/qterminal/color-schemes/puter.colorscheme"
  local q="$HOME/.config/qterminal.org/qterminal.ini"
  ini "$q" General colorScheme puter
  ini "$q" General fontFamily "puter-mono"
  ini "$q" General fontSize 11
  ini "$q" General TerminalMargin 0
  ini "$q" General highlightCurrentTerminal false
  # No scroll bar (it would leave the terminal 10px off the grid): the wheel
  # and Shift+PageUp scroll back.
  ini "$q" General ScrollbarPosition 0
  ini "$q" General SaveSizeOnExit false
  ini "$q" General SavePosOnExit false
  ini "$q" MainWindow fixedSize "@Size(720 540)"

  # LXImage-Qt: 24 x 18 modules, like every app.
  local l="$HOME/.config/lximage-qt/settings.conf"
  ini "$l" Window RememberWindowSize false
  ini "$l" Window FixedWidth 720
  ini "$l" Window FixedHeight 540
  ini "$q" General HideTabBarWithOneTab true
  ini "$q" General AskOnExit false
  ini "$q" General MenuVisible true

  # qpdfview: the page as wide as the window, pages one module apart, each
  # with a 1px edge, on bone (theme/qpdfview/colors, from theme/make); the
  # tab bar only for two or more, no toolbars, and closing the last tab
  # closes the window.
  local p="$HOME/.config/qpdfview/qpdfview.conf" key value
  ini "$p" documentView scaleMode 1
  ini "$p" documentView pageSpacing 30
  ini "$p" pageItem decoratePages true
  while read -r key value; do
    ini "$p" pageItem "$key" "$value"
  done <"$repo/theme/qpdfview/colors"
  ini "$p" mainWindow tabVisibility 0
  ini "$p" mainWindow fileToolBar ""
  ini "$p" mainWindow editToolBar ""
  ini "$p" mainWindow viewToolBar ""
  ini "$p" mainWindow exitAfterLastTab true

  # Archives (LXQt's archiver): the list alone, as in Files (no folder tree,
  # toolbar or status bar), 16px icons.
  local a="$HOME/.config/lxqt/archiver.conf"
  ini "$a" Window DirTree false
  ini "$a" Window ToolBar false
  ini "$a" Window StatusBar false
  ini "$a" Sizes ViewsIconSize 16
  ini "$a" Sizes WindowSize "@Size(720 540)"

  # The system monitor (qps): only your own programs, by name, with their
  # processor and memory use; none of its meters, control row or status bar
  # (only the list, as in Files); every two seconds.
  local m="$HOME/.config/qps/qps.conf"
  ini "$m" General flags "ExitOnClose, selectpids"
  ini "$m" General field "47, 42, 32"
  ini "$m" General viewproc 1
  ini "$m" General interval 2000
  ini "$m" sort field 42

  # Which app opens what.
  ln -sfn "$repo/config/mimeapps.list" "$HOME/.config/mimeapps.list"

  # What the apps are called (config/apps.names): a copy of each one's
  # desktop file with its plain name and none of its translated or generic
  # names, or kept out of search (a hidden one keeps its name: a desktop
  # file without one doesn't count, and the system's would show instead).
  python3 - "$repo/config/apps.names" <<'NAMES'
import pathlib, re, sys
apps = pathlib.Path.home() / ".local/share/applications"
apps.mkdir(parents=True, exist_ok=True)
for line in pathlib.Path(sys.argv[1]).read_text().splitlines():
    line = line.split("#", 1)[0].strip()
    if not line:
        continue
    desktop, name = line.split(None, 1)
    source = pathlib.Path("/usr/share/applications") / desktop
    if not source.exists():
        continue
    out, entry = [], False
    for row in source.read_text().splitlines():
        if row.startswith("["):
            entry = row == "[Desktop Entry]"
        elif entry and re.match(r"NoDisplay=" if name == "hide" else r"(Name|GenericName)(\[.*\])?=|NoDisplay=", row):
            continue
        out.append(row)
        if row == "[Desktop Entry]":
            out.append("NoDisplay=true" if name == "hide" else f"Name={name}")
    (apps / desktop).write_text("\n".join(out) + "\n")
NAMES

  agents

  on_bus bash -c "repo=$(printf %q "$repo"); $(declare -f settings); settings"
}

# Coding agents (bin/puter-agent): each opens in its own foot window, from
# search or a folder's menu in PCManFM-Qt, in a folder it trusts; their hooks
# tell the bar what they're doing; both get the desktop through puter-desktop (an MCP server)
# and are told about puter (config/agents/AGENTS.md).
agents() {
  local apps="$HOME/.local/share/applications" actions="$HOME/.local/share/file-manager/actions"
  mkdir -p "$apps" "$actions"
  local agent name
  for agent in claude codex; do
    name=${agent^}
    [[ $agent == claude ]] && name="Claude Code"
    cat >"$apps/$agent.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=$name
Comment=A coding agent, in its own window
Exec=$repo/bin/puter-agent $agent
Icon=$agent
Terminal=false
Categories=Development;
DESKTOP
    cat >"$actions/$agent.desktop" <<ACTION
[Desktop Entry]
Type=Action
Name=Open in $name
Icon=$agent
Profiles=folder;

[X-Action-Profile folder]
MimeTypes=inode/directory;
Exec=$repo/bin/puter-agent $agent %f
ACTION
  done

  # The hooks (config/agents/hooks.json), merged into each agent's own: any
  # other hooks stay.
  python3 - "$repo" <<'HOOKS'
import json, pathlib, sys
repo = pathlib.Path(sys.argv[1])
ours = json.loads((repo / "config/agents/hooks.json").read_text().replace("@puter-agent", str(repo / "bin/puter-agent")))
home = pathlib.Path.home()
for path in (home / ".claude/settings.json", home / ".codex/hooks.json"):
    path.parent.mkdir(parents=True, exist_ok=True)
    settings = json.loads(path.read_text()) if path.exists() else {}
    hooks = settings.setdefault("hooks", {})
    for event, entries in ours["hooks"].items():
        kept = [e for e in hooks.get(event, [])
                if not any("puter-agent hook" in h.get("command", "") for h in e.get("hooks", []))]
        hooks[event] = kept + entries
    path.write_text(json.dumps(settings, indent=2) + "\n")
# Claude Code's settings (config/agents/claude.json), merged into its own,
# which it rewrites: neither agent asks before it acts, since puter has nothing
# sensitive on it, so it starts in bypass-permissions mode without the
# warning; its status line is bin/puter-statusline; and dictation is on
# (hold Space to speak). It updates itself
# (bin/puter-update runs `claude update` too), so nothing turns that off.
claude = home / ".claude/settings.json"
settings = json.loads(claude.read_text())
ours = json.loads((repo / "config/agents/claude.json").read_text().replace("@puter-statusline", str(repo / "bin/puter-statusline")))
for key, value in ours.items():
    if isinstance(value, dict):
        settings.setdefault(key, {}).update(value)
    else:
        settings[key] = value
env = settings.get("env", {})
env.pop("DISABLE_AUTOUPDATER", None)
if not env:
    settings.pop("env", None)
claude.write_text(json.dumps(settings, indent=2) + "\n")
# and Codex never asks for approval and runs outside its sandbox (top-level
# keys, so before any table in its config).
codex = home / ".codex/config.toml"
lines = codex.read_text().splitlines() if codex.exists() else []
ours = {"approval_policy": '"never"', "sandbox_mode": '"danger-full-access"'}
table = next((i for i, line in enumerate(lines) if line.lstrip().startswith("[")), len(lines))
top = [line for line in lines[:table] if line.split("=")[0].strip() not in ours]
codex.write_text("\n".join([f"{key} = {value}" for key, value in ours.items()] + top + lines[table:]) + "\n")
# Claude Code in the terminal's own colours (the palette's), dark or light
# as the palette is (theme/mode).
config = home / ".claude.json"
settings = json.loads(config.read_text()) if config.exists() else {}
settings["theme"] = (repo / "theme/mode").read_text().strip() + "-ansi"
config.write_text(json.dumps(settings, indent=2) + "\n")
HOOKS

  # The desktop, for both.
  local claude="$HOME/.local/bin/claude"
  if [[ -x $claude ]]; then
    "$claude" mcp remove --scope user puter >/dev/null 2>&1 || true
    "$claude" mcp add --scope user puter -- "$repo/bin/puter-desktop" >/dev/null
  fi
  if command -v codex >/dev/null; then
    codex mcp remove puter >/dev/null 2>&1 || true
    codex mcp add puter -- "$repo/bin/puter-desktop" >/dev/null
  fi

  # What they're told about puter, unless there are instructions of the
  # user's own already.
  local file
  for file in "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md"; do
    if [[ ! -e $file || -L $file ]]; then
      ln -sfn "$repo/config/agents/AGENTS.md" "$file"
    fi
  done

  # Claude Code's keys (config/agents/claude-keybindings.json): Shift+Tab
  # doesn't cycle the permission mode, since it stays on bypass.
  ln -sfn "$repo/config/agents/claude-keybindings.json" "$HOME/.claude/keybindings.json"
}

# puter is for workshops and other machines with nothing sensitive on them,
# so nothing ever asks for a password: sudo doesn't, polkit (Wi-Fi, disks,
# power) doesn't, and the machine starts straight into the desktop.
access() {
  # sudo: anything, without a password (checked before it's put in place,
  # since a broken sudoers file locks sudo out).
  local rule
  rule="$(mktemp)"
  echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" >"$rule"
  sudo visudo -cqf "$rule"
  sudo install -m 440 -o root -g root "$rule" /etc/sudoers.d/10-puter
  rm -f "$rule"

  # polkit: every action allowed, for this user.
  sudo install -d -m 755 /etc/polkit-1/rules.d
  sudo tee /etc/polkit-1/rules.d/10-puter.rules >/dev/null <<RULES
// puter (install.sh): nothing asks $USER for a password.
polkit.addRule(function (action, subject) {
    if (subject.user == "$USER")
        return polkit.Result.YES;
});
RULES

  remote
}

# SSH, to fix the machine from another one when its screen or Wi-Fi won't:
# by key only (the keys in config/ssh/authorized_keys, followed as the
# checkout is updated), never by password, since there are none. avahi
# makes it puter.local, so no address needs looking up. A Thunderbolt cable
# straight to a Mac (its Thunderbolt Bridge) comes up on link-local
# addresses, as there's no DHCP across it.
remote() {
  local conf
  conf="$(mktemp)"
  cat >"$conf" <<SSHD
# puter (install.sh): in by key only.
AuthorizedKeysFile .ssh/authorized_keys $repo/config/ssh/authorized_keys
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
PermitRootLogin no
SSHD
  sudo install -d -m 755 /etc/ssh/sshd_config.d
  sudo install -m 644 -o root -g root "$conf" /etc/ssh/sshd_config.d/10-puter.conf
  rm -f "$conf"
  # (Arch's sshd_config reads the drop-ins; should it ever stop, it reads them again.)
  grep -q '^Include /etc/ssh/sshd_config.d/' /etc/ssh/sshd_config ||
    sudo sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' /etc/ssh/sshd_config
  # (Its host keys now rather than on the first boot, so the check has them.)
  sudo ssh-keygen -A
  sudo sshd -t

  sudo install -d -m 700 /etc/NetworkManager/system-connections
  sudo tee /etc/NetworkManager/system-connections/puter-thunderbolt.nmconnection >/dev/null <<'NM'
[connection]
id=Thunderbolt cable
type=ethernet
autoconnect=true

[match]
interface-name=thunderbolt*

[ipv4]
method=link-local

[ipv6]
method=link-local
NM
  sudo chmod 600 /etc/NetworkManager/system-connections/puter-thunderbolt.nmconnection

  sudo systemctl enable sshd.service avahi-daemon.service
}

login() {
  # greetd: no login screen, labwc as this user on boot and again after
  # logging out.
  sudo tee /etc/greetd/config.toml >/dev/null <<TOML
[terminal]
vt = 1

[default_session]
command = "labwc"
user = "$USER"
TOML
  sudo systemctl enable greetd.service NetworkManager.service
  # (A machine's own package, packages.txt.)
  if pacman -Q bluez >/dev/null 2>&1; then sudo systemctl enable bluetooth.service; fi
}

case "${1:-all}" in
  config)
    config
    ;;
  packages)
    packages
    ;;
  access)
    access
    ;;
  login)
    login
    ;;
  remote)
    remote
    ;;
  all)
    # First, so nothing after it asks for the password again.
    access
    packages
    login
    echo "Done. Reboot to log in to puter."
    ;;
  *)
    echo "usage: $0 [config|packages|access|login|remote]" >&2
    exit 1
    ;;
esac
