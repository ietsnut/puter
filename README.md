# puter

My Arch desktop: labwc for floating windows, Quickshell for the bar, desk and
search, in three colours (black, gray, white) on a 30px module, square and flat, with
icons in clean 2px vector strokes.

| Folder | What it is |
| --- | --- |
| `labwc/` | the compositor: window behaviour, keys, title bars, the desktop menu |
| `quickshell/` | the shell in QML: desk, bottom bar, search; `Theme.qml` holds every size and colour |
| `theme/` | the labwc theme: title bars, and the window buttons `make-buttons` writes |
| `fontconfig/` | text smoothed in grays only |
| `ghostty/` | the terminal |
| `install.sh` | links those folders into `~/.config` |
| `dev/` | work from the Mac: `sync`, `shot`, `run` |

## Working on it

The desktop runs in an Arch VM on the devbox (`ssh archvm`). Edit here, then
`dev/sync` copies the checkout to `~/puter` on the VM and reloads, and
`dev/shot` saves a screenshot to `dev/shot.png`. `dev/run ghostty` opens a
window on it and `dev/click X Y` clicks at a point in screenshot pixels.

The VM has no GPU, and wlroots crashes on OpenGL apps' native Wayland frames
there, so run those through XWayland: `dev/run env GDK_BACKEND=x11 kicad`.

## Keys

Super+Return terminal, Super+Space search, Super+Escape menu (or right-click
the desktop), Super+Q close, Super+F maximise, Alt+Tab switch windows.
Super+Left/Right snap a window to half the screen and Super+Up maximises;
dragging a title bar to an edge does the same, and corners give quarters.
