# puter

My Arch desktop: labwc for floating windows, Quickshell for the bar, desk and
search, and Qt Widgets apps, all on a 30px module, square and flat, with IBM's
Carbon icons. Made for workshops and machines with nothing sensitive on
them: nothing asks for a password (sudo, polkit, the login), like Kali.
Two looks, one palette file each: `stack` (a
dotted brown desk, bone title bars, a colour for every app)
and `mulholland` (black, white and gray, IBM Plex).

| Path | What it is |
| --- | --- |
| `install.sh` | sets up a plain Arch install: packages, configs, no passwords, straight into the desktop |
| `packages.txt` | everything it installs: Arch's packages and puter's own (`[puter]`), a few marked for one architecture |
| `config/` | linked into `~/.config` as is: `labwc/` (windows, keys, snapping, the desktop menu), `quickshell/` (the shell in QML: desk, bar, search, notifications, agents' states; `Theme.qml` holds every size), `agents/` (the agents' hooks and what they're told), `apps.names` (what each app is called), the portals (one file dialog for every app), fonts, GTK settings, which app opens what |
| `theme/` | the look: `palettes/mulholland` assigns colours to every role, `make` writes every app's colours, buttons and icons from it; the Qt stylesheet (`qt/puter.qss`) and GTK 3 theme are edited here |
| `bin/` | puter's commands: `puter-agent` (Claude Code and Codex as apps, and their hooks for the bar), `puter-desktop` (the desktop as an MCP server for them), `puter-update` (everything to the newest), `puter-mode` (light or dark) |
| `src/` | puter's own code: `style/` (the Qt widget style every Qt app uses), `sheet/` (the table editor), `calc/` (the calculator) and `windows/` (lists windows for the switcher's previews) |
| `packages/` | puter's pacman repository, `[puter]`, built and signed in CI (`build`, `.github/workflows/packages.yml`): labwc with `snap.patch` (windows meet on one line), qps, wlrctl, qpdfview, JLCONE from JLCPCB's .deb, and `puter-apps` (`src/`); `puter.gpg` is its key |
| `iso/` | the USB installer: `build` makes it (Arch's install medium with every package on it, so it installs offline), `airootfs/usr/local/bin/puter-install` asks which disk and installs, `download` fetches the newest from `ghcr.io/ietsnut/puter-iso` |
| `vm/` | puter on a Mac with Apple silicon: `try` downloads puter's virtual machine (the aarch64 build, installed) from `ghcr.io/ietsnut/puter-vm` and starts it in QEMU at the Mac's own speed; `build` makes it |

## Installing

On a fresh Arch install (archinstall, minimal profile, NetworkManager, a user
with sudo):

```
git clone https://github.com/ietsnut/puter ~/puter
~/puter/install.sh
```

then reboot. Or write the USB installer to a stick (`iso/download`, then
balenaEtcher or Raspberry Pi Imager): it installs offline, asking only
which disk to erase. `install.sh config` only relinks the configs and
reapplies settings; `install.sh packages` installs everything, as an update
(`bin/puter-update`).

## How it's built and shipped

Nothing is compiled on a puter machine. GitHub's runners do it all, and
only the newest of everything is kept:

| What | Built by | Where it goes | When |
| --- | --- | --- | --- |
| `[puter]`, puter's pacman repository (`packages/`, `src/`), for x86_64 and aarch64, signed with `packages/puter.gpg` (the private key is the `PUTER_SIGNING_KEY` secret) | `.github/workflows/packages.yml` | the `repo` and `repo-aarch64` releases, which `puter-update` lists above Arch's own | pushes touching `packages/` or `src/`, daily (to follow Arch, the AUR, JLCPCB, OpenAI and Qt), by hand |
| The USB installer, `puter.iso` (about 3.7 GB, x86_64), test-installed and started in QEMU before it's published | `.github/workflows/iso.yml` | `ghcr.io/ietsnut/puter-iso` (`iso/download`) | pushes touching `iso/`, weekly, by hand |
| The Mac's virtual machine, `puter.qcow2` (about 3 GB, aarch64: Arch Linux ARM, so no JLCONE) | `.github/workflows/vm.yml` | `ghcr.io/ietsnut/puter-vm` (`vm/try`) | pushes touching `vm/build` or the installer, weekly, by hand |

Machines follow `main`: `puter-update` (the bar's update button) pulls
this repository and takes `[puter]`'s packages with Arch's.

## Changing colours

Put a palette's name in `theme/palette` (or edit its file in `theme/palettes/`),
run `theme/make`, then `./install.sh config` on the machine.

Every palette has a light look and a dark one: its `[dark]` section lists the
roles that differ, and `theme/make` writes the light look into `theme/` and
the dark one into `theme/dark/`, both committed. The sun and moon in the bar
switch the whole machine (`bin/puter-mode light|dark|toggle`, which
`install.sh look` points everything at): the bar, title bars and GTK apps at
once, Qt apps, Firefox, Thunderbird and the terminals once opened again.

## Working on it, on a Mac

On a Mac with Apple silicon, puter runs in a window at the Mac's own speed:
the aarch64 build in QEMU with Apple's hypervisor (`vm/try`), with this
checkout copied in as its `~/puter`, so it runs what you edit.

Start it (the first time downloads about 3 GB into
`~/Library/Caches/puter`; it's up about a minute later):

```
brew install qemu
vm/try
```

Then, in another terminal, leave `vm/try watch` running: each file you save
here is copied in, so Quickshell reloads QML by itself (on screen within a
second) and labwc reloads its config. For the rest:

| | |
| --- | --- |
| `vm/try apply` | after `theme/make`, or changing what `install.sh` sets up (about 20 seconds) |
| `vm/try reload` | labwc and Quickshell again, at once |
| `vm/try do CMD` | a command in its desktop session, its output here (`vm/try do 'setsid -f featherpad'` opens an app) |
| `vm/try shot [FILE]` | a screenshot (`/tmp/puter.png` unless given) |
| `vm/try update` | the newest published machine, starting over on it |
| `vm/try fresh` | start over on the one downloaded |

To try a change to `src/` (the Qt style, Sheet, Calculator), build it in
the machine (once: `vm/try do 'sudo pacman -Sy --noconfirm cmake gcc make'`):

```
vm/try apply
vm/try do 'cmake -S ~/puter/src/style -B /tmp/style -DCMAKE_INSTALL_PREFIX=/usr && cmake --build /tmp/style && sudo cmake --install /tmp/style'
```

then restart the app. Commit and push when it's right: CI builds it into
`[puter]` for every machine.

Stop it by closing its window (or `vm/try do 'sudo poweroff'`); what you
changed in it is kept for next time. To clean it all up:

```
rm -rf ~/Library/Caches/puter
```

To build the machine here instead of downloading it (about 15 minutes, 20
GB of Docker space while it builds; commit first, since it installs what's
committed):

```
packages/container
docker run --rm --privileged -v /dev:/dev -v "$PWD:/puter:ro" -v puter-work:/work arch /puter/vm/build /work/build /work/out
mkdir -p ~/Library/Caches/puter
docker run --rm -v puter-work:/work -v ~/Library/Caches/puter:/out arch mv /work/out/puter.qcow2 /out/
vm/try fresh
```

and to clean that up as well: `docker volume rm puter-work` and
`docker rmi arch arch-root`.

## Apps

Every app is called what it is (`config/apps.names`): Files (PCManFM-Qt: back, the folder's whole path, and a terminal opened there),
Notepad (FeatherPad, syntax colours from the palette), Photos (LXImage-Qt),
Video (mpv), Terminal (QTerminal), Browser (Firefox, laid out like Chrome: tabs with close and new-tab buttons, downloads and the menu at the right), Mail (Thunderbird), Sheets (puter's own),
PDFs (qpdfview), Archives (LXQt's archiver), Calculator (puter's own) and
System Monitor (qps); KiCad and JLCONE (PCB orders) keep their own names; helpers that come with a package (foot's server, CMake, the Qt test
tools) are kept out of search.
Claude Code and Codex, each session in a window of its own (search, or
right-click a folder: Open in Claude Code); its taskbar tab shows whether
it's working, waiting for you (orange) or done, and both can see and use the
desktop.
Notifications come up as toasts in the top-right corner, each with a strip
in its app's colour (orange when critical). Left of the clock, light or dark (the sun and moon), the network (click for
nmtui: networks, Wi-Fi and its passwords) and the volume (click for a
slider, scroll to turn it up or down);
right of it, updates, then restart and shut down in the bar's right corner.
Updates shows what's out of date and, with one click, brings everything to
the newest there is (`bin/puter-update`): Arch and the kernel, puter's own
packages (`[puter]`), firmware, puter itself and Claude Code, with the
output and progress as it goes.

## Keys

Super+Return terminal, Super+Space or the Windows key (Command on a Mac
keyboard) on its own for search, Super+Escape menu (or right-click
the desktop), Super+Q close, Super+F maximise. Alt+Tab switches windows:
a quick tap goes back to the last one; held, it shows every window as a
card with a live preview (Tab and Shift+Tab or the arrows to pick, let go
of Alt to go there, Delete to close one, Escape to stay).
Super+Left/Right snap a window to half the screen and Super+Up maximises;
dragging a title bar to an edge does the same, and corners give quarters.
