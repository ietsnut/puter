# puter

My Arch desktop: labwc for floating windows, Quickshell for the bar and
everything else on screen, in the Electronaut look (flat chips on a 30px
module, a closed palette, no rounding or shadows).

| Folder | What it is |
| --- | --- |
| `labwc/` | the compositor: window behaviour, keys, title bars, the desktop menu |
| `quickshell/` | the shell in QML; `Theme.qml` holds every size and colour |
| `ghostty/` | the terminal |
| `install.sh` | links those folders into `~/.config` |
| `dev/` | work from the Mac: `sync`, `shot`, `run` |

## Working on it

The desktop runs in an Arch VM on the devbox (`ssh archvm`). Edit here, then
`dev/sync` copies the checkout to `~/puter` on the VM and reloads, and
`dev/shot` saves a screenshot to `dev/shot.png`. `dev/run ghostty` opens a
window on it.

## Keys

Super+Return terminal, Super+Escape menu (or right-click the desktop),
Super+Q close, Super+F maximise, Alt+Tab switch windows.
