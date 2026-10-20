# puter

My Arch desktop: labwc for floating windows, Quickshell for the bar, desk and
search, in three colours (black, gray, white) on a 30px module, square and flat, with
icons in clean 2px vector strokes.

| Path | What it is |
| --- | --- |
| `install.sh` | sets up a plain Arch install: packages, Geist, configs, login screen |
| `packages.txt` | everything it installs from the Arch repos |
| `labwc/` | the compositor: window behaviour, keys, snapping, the desktop menu |
| `quickshell/` | the shell in QML: desk, bottom bar, search; `Theme.qml` holds every size |
| `theme/colors` | the palette (Apollo) and its roles; `theme/make` writes every app's colours and icons from it |
| `theme/` | labwc's title bars and buttons, the GTK theme, the line icons |
| `ghostty/`, `fontconfig/`, `gtk-3.0/` | terminal, text smoothing, GTK settings |
| `dev/` | work from the Mac: `sync`, `shot`, `click`, `run` |

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

Edit `theme/colors`, run `theme/make`, then `dev/sync`.

## Working on it

The desktop runs in an Arch VM on the devbox (`ssh archvm`). Edit here, then
`dev/sync` copies the checkout to `~/puter` on the VM, runs `install.sh config`
and reloads, and
`dev/shot` saves a screenshot to `dev/shot.png`. `dev/run ghostty` opens a
window on it and `dev/click X Y` clicks at a point in screenshot pixels.

The VM has no GPU, and wlroots crashes on OpenGL apps' native Wayland frames
there, so run those through XWayland: `dev/run env GDK_BACKEND=x11 kicad`.

## Keys

Super+Return terminal, Super+Space search, Super+Escape menu (or right-click
the desktop), Super+Q close, Super+F maximise, Alt+Tab switch windows.
Super+Left/Right snap a window to half the screen and Super+Up maximises;
dragging a title bar to an edge does the same, and corners give quarters.
