# puter

> How it's built and why: `NOTES.md`. What's left: `NEXT.md`. The dev VM: `dev/devbox/README.md`.

My Arch desktop: labwc for floating windows, Quickshell for the bar, desk and
search, and Qt Widgets apps, all on a 30px module, square and flat, with IBM's
Carbon icons. Made for workshops and machines with nothing sensitive on
them: nothing asks for a password (sudo, polkit, the login), like Kali.
Two looks, one palette file each: `stack` (a
dotted brown desk, bone title bars, a colour for every app)
and `mulholland` (black, white and gray, IBM Plex).

| Path | What it is |
| --- | --- |
| `install.sh` | sets up a plain Arch install: packages, builds, configs, no passwords, straight into the desktop |
| `packages.txt` | everything it installs from the Arch repos |
| `config/` | linked into `~/.config` as is: `labwc/` (windows, keys, snapping, the desktop menu), `quickshell/` (the shell in QML: desk, bar, search, notifications, agents' states; `Theme.qml` holds every size), `agents/` (the agents' hooks and what they're told), `apps.names` (what each app is called), the portals (one file dialog for every app), fonts, GTK settings, which app opens what |
| `theme/` | the look: `palettes/mulholland` assigns colours to every role, `make` writes every app's colours, buttons and icons from it; the Qt stylesheet (`qt/puter.qss`) and GTK 3 theme are edited here |
| `bin/` | puter's commands: `puter-agent` (Claude Code and Codex as apps, and their hooks for the bar), `puter-desktop` (the desktop as an MCP server for them), `puter-update` (everything to the newest) |
| `src/` | puter's own code: `style/` (the Qt widget style every Qt app uses), `sheet/` (the table editor), `calc/` (the calculator) and `windows/` (lists windows for the switcher's previews) |
| `packages/` | Arch recipes it builds: labwc with `snap.patch` (windows meet on one line), wlrctl, qpdfview, JLCONE from JLCPCB's .deb |
| `dev/` | work from the Mac: `sync`, `shot`, `grid`, `click`, `run`, `screen`; `devbox/` is the dev VM's setup; screenshots land in `dev/shots/` |

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
`dev/grid` checks one against the grid. `dev/screen` opens the VM's desktop live in Screen
Sharing (`dev/screen stop` closes the tunnel), `dev/run qterminal` opens a
window on it and `dev/click X Y` clicks at a point in screenshot pixels.

The VM has no GPU, and wlroots crashes on OpenGL apps' native Wayland frames
there, so run those through XWayland: `dev/run env GDK_BACKEND=x11 kicad`.

## Apps

Every app is called what it is (`config/apps.names`): Files (PCManFM-Qt),
Notepad (FeatherPad, syntax colours from the palette), Photos (LXImage-Qt),
Video (mpv), Terminal (QTerminal), Browser (Firefox), Mail (Thunderbird), Sheets (puter's own),
PDFs (qpdfview), Archives (LXQt's archiver), Calculator (puter's own) and
System Monitor (qps); KiCad and JLCONE (PCB orders) keep their own names; helpers that come with a package (foot's server, CMake, the Qt test
tools) are kept out of search.
Claude Code and Codex, each session in a window of its own (search, or
right-click a folder: Open in Claude Code); its taskbar tab shows whether
it's working, waiting for you (orange) or done, and both can see and use the
desktop.
Notifications come up as toasts in the top-right corner, each with a strip
in its app's colour (orange when critical). Left of the clock, the network (click for nmtui: networks, Wi-Fi and its
passwords) and the volume (click to mute, scroll to turn it up or down);
right of it, updates, then restart and shut down in the bar's right corner.
Updates shows what's out of date and, with one click, brings everything to
the newest there is (`bin/puter-update`): Arch and the kernel, firmware,
puter itself, the packages it builds, its own apps and Claude Code, with
the output and progress as it goes.

## Keys

Super+Return terminal, Super+Space or the Windows key (Command on a Mac
keyboard) on its own for search, Super+Escape menu (or right-click
the desktop), Super+Q close, Super+F maximise. Alt+Tab switches windows:
a quick tap goes back to the last one; held, it shows every window as a
card with a live preview (Tab and Shift+Tab or the arrows to pick, let go
of Alt to go there, Delete to close one, Escape to stay).
Super+Left/Right snap a window to half the screen and Super+Up maximises;
dragging a title bar to an edge does the same, and corners give quarters.
