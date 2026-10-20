# puter

> How it's built and why: `NOTES.md`. What's left: `NEXT.md`. The dev VM: `dev/devbox/README.md`.

My Arch desktop: labwc for floating windows, Quickshell for the bar, desk and
search, and Qt Widgets apps, all on a 30px module, square and flat, with icons
in clean 2px vector strokes. Two looks, one palette file each: `stack` (a
dotted charcoal desk, bone title bars, a colour for every app, Stack Sans)
and `mulholland` (black, white and gray, IBM Plex).

| Path | What it is |
| --- | --- |
| `install.sh` | sets up a plain Arch install: packages, builds, configs, login screen |
| `packages.txt` | everything it installs from the Arch repos |
| `config/` | linked into `~/.config` as is: `labwc/` (windows, keys, snapping, the desktop menu), `quickshell/` (the shell in QML: desk, bar, search, settings; `Theme.qml` holds every size), the portals (one file dialog for every app), fonts, GTK settings, which app opens what |
| `theme/` | the look: `palettes/mulholland` assigns colours to every role, `make` writes every app's colours, buttons and icons from it; the Qt stylesheet (`qt/puter.qss`) and GTK 3 theme are edited here |
| `src/` | puter's own code: `style/` (the Qt widget style every Qt app uses) and `sheet/` (the table editor) |
| `packages/` | Arch recipes it builds: labwc with `snap.patch` (windows meet on one line), JLCONE from JLCPCB's .deb |
| `dev/` | work from the Mac: `sync`, `shot`, `grid`, `tour`, `click`, `run`, `screen`; `devbox/` is the dev VM's setup; screenshots land in `dev/shots/` |

## Installing

On a fresh Arch install (archinstall, minimal profile, NetworkManager, a user
with sudo):

```
git clone https://github.com/ietsnut/puter ~/puter
~/puter/install.sh
```

then reboot. `install.sh config` only relinks the configs and reapplies
settings; `install.sh packages` only installs packages.

## Changing colours

Put a palette's name in `theme/palette` (or edit its file in `theme/palettes/`),
run `theme/make`, then `dev/sync`.

## Working on it

The desktop runs in an Arch VM on the devbox (`ssh archvm`). Edit here, then
`dev/sync` copies the checkout to `~/puter` on the VM, runs `install.sh config`
and reloads. `dev/shot` saves a screenshot to `dev/shots/shot.png`;
`dev/grid` checks one against the grid, and `dev/tour` opens every app and
dialog and checks each. `dev/screen` opens the VM's desktop live in Screen
Sharing (`dev/screen stop` closes the tunnel), `dev/run qterminal` opens a
window on it and `dev/click X Y` clicks at a point in screenshot pixels.

The VM has no GPU, and wlroots crashes on OpenGL apps' native Wayland frames
there, so run those through XWayland: `dev/run env GDK_BACKEND=x11 kicad`.

## Apps

PCManFM-Qt for files, FeatherPad for text and code (syntax colours from the
palette), LXImage-Qt for photos, mpv for video, QTerminal for the terminal,
qutebrowser for the web (o to open, : for commands), Sheet (puter's own) for tables, JLCONE for PCB orders.
Left of the clock, the network (click for nmtui: networks, Wi-Fi and its
passwords) and the volume (click to mute, scroll to turn it up or down);
restart and shut down in the bar's right corner.

## Keys

Super+Return terminal, Super+Space search, Super+Escape menu (or right-click
the desktop), Super+Q close, Super+F maximise, Alt+Tab switch windows.
Super+Left/Right snap a window to half the screen and Super+Up maximises;
dragging a title bar to an edge does the same, and corners give quarters.
