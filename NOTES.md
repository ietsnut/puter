# puter: how it's built, and why

A record of the decisions so far (October 2026), so the next session starts
from what was learned rather than repeating it. `README.md` says what's where;
`NEXT.md` says what's left; `dev/devbox/README.md` covers the dev VM.

## The rules

- **Everything on the grid.** The module is 30px. Every edge (bars, rows,
  tabs, buttons, panels, highlights) sits on a multiple of 30, text one 8px
  inset in. Measured from screenshots, never eyeballed. A tool that can't keep
  to it gets patched, restyled or replaced (fuzzel was, see below).
- **Floating windows**, never tiling. Snapping (Super+arrows, drag to an edge)
  gives halves and quarters, which land on the grid at 1920x1080.
- **One icon set: IBM's Carbon** (21 October, replacing puter's own line
  drawings), in ink, 16px glyphs one module square, every line sharp. No
  pixel art, no dithering.
- **One palette for everything**, from one file; square corners, no shadows,
  no blur, no animation.
- **Minimal and well supported.** Apps like KiCad must just work.
- **Only what's needed.** An app window is its title bar, its menu bar (every
  command lives there) and its content. No toolbars or status bars (the Qt
  stylesheet gives them no height, since apps show them regardless of their
  settings), no side panes, no tab strip for a single tab, no extra columns,
  buttons or promotions; each app's own settings in `install.sh` do the rest.

## The stack

| Part | What | Why |
| --- | --- | --- |
| Compositor | labwc | Floating by design, light, Raspberry Pi OS's default so ordinary apps are well tested on it; runs without a GPU |
| Shell | Quickshell (QML) | Desk, bottom bar, search, settings drawn exactly to the grid; reloads live; Qt's software renderer (a third of the memory) |
| Apps | Qt Widgets | One style and one stylesheet make every app uniform, and they're light (about 20 MB each) |
| Terminal | QTerminal | |
| Agents | Claude Code, Codex, each in foot | See "Agents" below |
| Files | PCManFM-Qt | |
| Text and code | FeatherPad | |
| Tables | Sheet (`src/sheet`, puter's own) | No maintained small Qt table editor exists |
| Photos | LXImage-Qt | |
| Video | mpv | No interface of its own |
| Mail | Thunderbird | Google, Microsoft (OAuth) and plain IMAP; Firefox's engine, so its whole interface is restyled by one stylesheet (`theme/thunderbird`, from the palette), like Firefox's. About 430 MB at rest |
| PDFs | qpdfview (`packages/qpdfview`, the AUR's recipe) | Qt Widgets on poppler, tabs only for two or more; pages on bone with a 1px edge |
| Archives | LXQt's archiver | Qt, the list alone as in Files; 7-Zip, unzip and zip do the work |
| Calculator | Calculator (`src/calc`, puter's own) on libqalculate | Qalculate's arithmetic (units, currencies, functions) under a grid of our own; SpeedCrunch 1.0 draws its own dark, rounded interface, and Qalculate's Qt app keeps its menus in a toolbar |
| System monitor | qps | Qt Widgets; only your programs, their processor and memory, without its meters |
| Web | Firefox | A normal browser (tabs, an address field), its whole interface restyled by one stylesheet (`theme/firefox`, from the palette) and its settings a web page |
| PCB orders | JLCONE | JLCPCB's Electron app, from their .deb (`packages/jlcone-bin`, the AUR's recipe) |
| Login | greetd | None: labwc as the user, on boot and after logging out |
| Fonts | IBM Plex Sans, IBM Plex Mono | The dental desk's and its reports' font; `ttf-ibm-plex` from extra |

Tried and dropped: Hyprland, niri and sway (tiling), KDE Plasma (heavy, its
own look), Wayfire, waybar, fuzzel, swaybg, Docker previews on the Mac,
dithering, pixel-art icons, the PICO-8 and Apollo palettes and Geist (replaced
by the Mulholland look, 20 October 2026), Gnumeric, Apostrophe, Chromium, and on 21 October Falkon (its preferences, a
big form of its own, can't be made tidy by the style) and qutebrowser (its
bars fit the grid, but it's driven by commands, not an address field).
Then, the same day, every app for a Qt Widgets one: GTK 3 apps (Thunar,
Mousepad) hard-code their spacing and needed patches; GTK 4 and libadwaita
apps (Comma, Nautilus, GNOME Text Editor, Loupe, GNOME Web) each lay out their
header bars differently and use 100-230 MB each; Firefox needs a stylesheet of
its own. KDE's apps (with full Plasma or on labwc) were weighed too: uniform,
but Plasma costs an estimated 300-600 MB more than labwc and Quickshell.

## How the look is made

- `theme/palettes/mulholland` (the only one) assigns colours to every role:
  the interface (desk, paper, ink, accent, muted, outline, rule, title,
  hover), syntax, the terminal's sixteen ANSI colours, KiCad's colours. It is
  the look of Mulholland's dental desk and reports: black, white and IBM
  Carbon grays, 1px black outlines, light gray rules inside tables. Accent
  colours (blue, coral, pink, from the website) are in the palette but no role
  uses them yet: hover and highlights are gray. A window looks the same
  focused or not; only its taskbar tab shows the focus.
- `theme/palettes/stack` (20 October 2026), after Koto's Stack Overflow
  identity and Butterfly's Pond: a charcoal desk with a dot at every module
  corner, paper windows under bone title bars, a bone taskbar whose focused
  tab is paper, lilac selection, and one colour per app, shown as a 14px
  square one inset in on its title bar (labwc's `icon` button, which opens
  the window menu) and its taskbar tab. Set in IBM Plex, like mulholland
  (Stack Sans was tried and dropped, 21 October).
- **The bar's right end**: network, volume, the clock, restart and shut
  down, each a one-module glyph (`BarButton.qml`) drawn like the window
  buttons. The network's state comes from `nmcli monitor`, which waits for
  changes rather than polling; clicking it opens nmtui. There's no settings
  panel any more.
- A palette has roles, then `[colors]`, `[fonts]` (sans, mono, headline) and
  `[apps]` (an icon name and its colour; an app without a desktop file of
  its app ID, like the file dialog's portal, is listed by app ID). Every app
  is set in `puter-sans` and `puter-mono`, fontconfig aliases `theme/make`
  writes from `[fonts]` (`fc-match` reads a hyphen as a size: test with
  `fc-match 'puter\-sans'`). The app squares are icons in the puter theme.
- All text is 15px, sans and mono alike: Quickshell (`Theme.textSize`), Qt
  (qt6ct's fonts, FeatherPad's), GTK, Firefox and Thunderbird (their
  stylesheets), foot (`pixelsize=15`) and labwc's titles and menus, whose
  `<size>` puter's labwc reads in pixels (`packages/labwc/pixels.patch`;
  in whole points it could only be 14.67 or 16). The calculator's keys
  are one module tall, not larger text. The one exception is QTerminal:
  it takes a whole point size and writes it back on every close, so a
  pixel size wouldn't last; it's 11pt, 14.67px.
- `theme/make` writes everything from it: `config/quickshell/Colors.qml`, labwc's
  `themerc` and window buttons (with hover images), the icon theme, the GTK 3
  colours (KiCad), the Qt stylesheet and palette (`theme/qt6ct/`), FeatherPad's
  syntax colours, QTerminal's and foot's colours, and KiCad's theme. Generated files say
  so at the top; edit the palette, not them.
- **Qt apps** are styled in two parts, both read through qt6ct
  (`QT_QPA_PLATFORMTHEME` in `config/labwc/environment`):
  - `src/style` is puter's widget style, a plugin on Fusion: it takes away the
    frames, margins and layout spacing Qt keeps around bars and menus (in main
    windows; dialogs keep theirs), sets 16px icons, and table rows of 30 and
    columns of 150. A stylesheet can't reach these.
  - **Every dialog is laid on the grid by `src/style`** when it's shown
    (and once more after, as some apps size theirs late): a module of
    margin round it, nothing between its parts (apps' own Designer margins
    and spacing are overridden, fixed spacers rounded up), buttons a module
    apart, labels, buttons and fields at least their size rounded up to
    whole modules (single-line ones exactly one module tall), side lists
    and scroll areas whole modules wide, the dialog itself whole modules.
    Main windows open whole modules wide and tall; text tool buttons (path
    bars) and header columns round up too (a column rounds down where up
    would overrun the view, and the last, stretched one takes the rest).
    In dialogs, fields are ledger rows (a line under each), groups are a
    heading with no box, labels and checkboxes start one inset in. Tabs
    and scroll bars are sized by the style, not the stylesheet: tabs whole
    modules wide with no dividers, scroll bars a one-module gutter with a
    slim handle. Each app opens at 24 x 18 modules (`install.sh`).
  - `theme/qt/puter.qss` is the stylesheet: colours, outlines and rules, and
    the heights that pin each widget it styles to the 30px module. Qt sizes a
    widget from the stylesheet as soon as it gives it a border or background
    and adds a few pixels of its own, so heights are pinned (`min-height` and
    `max-height`, or `height`), not padded.
- **File dialogs** come from one place for every app: LXQt's portal, whose
  dialog is libfm-qt's (PCManFM-Qt's own, so styled like any Qt window).
  Qt apps reach it through qt6ct (`standard_dialogs=xdgdesktopportal`), GTK 3
  apps and Electron through `GTK_USE_PORTAL`, GTK 4 and Flatpaks by default;
  `config/xdg-desktop-portal/labwc-portals.conf` routes it. GTK 3 apps that build
  their own dialog rather than asking for a native one (wxWidgets, so KiCad)
  still show GTK's. The portal's systemd service sets
  `QT_QPA_PLATFORMTHEME=lxqt`; `config/systemd/` overrides it with qt6ct, or the
  dialog comes up in plain Fusion. The dialog is pared down in two places:
  `install.sh` writes `~/.config/lxqt/filedialog.conf` (list view, name,
  size and date, 720x480), and `src/style` takes away its side pane, toolbar
  (keeping its shortcuts), labels and margins, finding them by the names in
  libfm-qt's `filedialog.ui`; the file type row only shows with a choice of
  types.
- `config/quickshell/Theme.qml` holds the geometry (module 30, inset 8, IBM Plex Sans
  15px).
- `theme/gtk-3.0/gtk.css` restyles Adwaita for the GTK 3 apps that remain
  (KiCad). Most of it is overriding Adwaita rules that are more specific than
  a plain selector; the `:not(.puter-a):not(.puter-b)` selectors exist only to
  outrank them.
- `install.sh config` links the folders into `~/.config`, the theme and icons
  into `~/.local/share`, writes qt6ct's settings, sets the Qt apps' own
  options (FeatherPad, PCManFM-Qt, QTerminal) in their ini files, and applies
  gsettings (GTK reads its theme from gsettings on Wayland) and KiCad's.

## Agents

Claude Code and Codex are apps (21 October): `bin/puter-agent claude|codex
[folder]` opens a session in a window of its own, from search ("Claude
Code", "Codex", in home) or a folder's menu in PCManFM-Qt ("Open in Claude
Code", file-manager actions that install.sh writes).

- **The window is foot**, not QTerminal: it can give each window the agent's
  app ID (so labwc and the bar show the agent's square: Claude coral-dark,
  Codex cyan), lock its title, and it has what the agents' TUIs lean on:
  synchronized output (no flicker while they redraw), the kitty keyboard
  protocol (Shift+Enter for a new line) and truecolor. Its colours are the
  terminal's, written by `theme/make` (`theme/foot/foot.ini`), as its light
  theme, so both agents pick their light looks; Claude Code is set to
  `light-ansi`, drawing in those colours. 10 MB, no CPU at rest.
- **The bar shows what each agent is doing.** The window's title is locked
  to "Claude · folder" (a second one in the same folder is "… 2"), and both
  agents run `puter-agent hook` on their events (`config/agents/hooks.json`;
  Claude Code and Codex read the same format, merged by install.sh into
  `~/.claude/settings.json` and `~/.codex/hooks.json`). The hook tells the
  shell over IPC (`qs ipc call agents set TITLE STATE`, `Agents.qml`) and the
  tab with that title shows it in its last module: working (a prompt or a
  tool ran), waiting for a permission (the whole tab in `attention`, orange)
  or done (a check, until you've been to the window). Nothing is polled.
  Codex asks once to trust new hooks ("Hooks need review").
- **They can use the desktop**: `bin/puter-desktop`, an MCP server
  (standard-library Python, registered with both as `puter`): screenshot,
  windows, focus, click, move, scroll, type, key, open, through grim, wlrctl
  (built from the AUR's recipe, `packages/wlrctl`) and wtype. Each is asked
  for as any tool is. `config/agents/AGENTS.md` tells them about puter,
  linked as `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` unless there are
  instructions of the user's own.
- Claude Code comes from Anthropic's installer (`~/.local/bin`, it updates
  itself), Codex from extra (`openai-codex`). Signing in is each agent's own
  first screen.

## Mail

Thunderbird, set up like Firefox: `config/thunderbird/user.js` (its own
title bar off, so labwc's; three columns; the message list a table; no start
page, Thundermail, chat, donation or news popups, telemetry; new mail as a
toast) and `theme/thunderbird/userChrome.css`, from which `theme/make`
writes `chrome/` with the palette's colours and Carbon icons for the
folders. Both are linked into its profile in `~/.config/thunderbird`. The
window is 48 x 26 modules: the menu bar, then folders (9 modules), the list
(18) and the message (21), meeting on 1px rules. Every row is one module:
the list's height comes from Thunderbird's own sum, ceil(font size × 1.4) +
7 at normal density, which `mail.uifontsize` 16 makes 30 (the sheet keeps
the text at 15px). No unified toolbar, spaces column, pane headers, status
bar, message header buttons or avatars: their commands are in the menus.
The list shows the subject, who and when. The message header is three
one-module rows. Account setup is the account hub, flattened.

## The calculator

`src/calc`, twelve modules wide and fifteen tall: the menu bar, seven
history rows (the sum on the left in the muted ink, its result on the right),
the sum being typed, its result as you type (muted; ink and semibold once
Return or = has put it in the history), and the keypad, four keys across and
five down, each three modules by one, in the same 15px as everything
else, drawn by the app as one grid on 1px
rules (digits on paper, operators on bone, = in the accent; colours from
`CalcKeypad` in the stylesheet). A sum starting with an operator goes on from
the last result, kept to 32 digits so 1/3 then × 3 is 1. libqalculate is set
to work exactly where it can and print decimals, ten significant digits in
groups of three, no trailing zeros, E notation only past twenty digits, no
mixed units (3.106 856 mi, not 3 mi + 188 yd), and currencies left as they
are; "20% of 85" is read as 20% × 85. Up and Down recall sums, Escape clears,
a click on a history row puts its result in the sum. The history is kept.

## Notifications

`Toasts.qml` is the notification server (Quickshell's): toasts in the
top-right corner, one module in from the edges, twelve modules wide, the
newest on top and each flush under the last (they meet on one line). A
toast is a one-module strip in the app's colour (the palette's `[apps]`,
which `theme/make` also writes into `Colors.qml` as `apps`; the accent for
an app without one; `attention` when critical) with a Carbon glyph (a bell,
or a warning when critical), the app's name and a close button; then the
summary and body on paper, rounded up to whole modules; then the actions as
chips. A click takes the default action. A toast goes after its timeout (six
seconds unless the app says), a critical one stays. No animation, and
nothing runs while there are none.

## Alt+Tab

`Switcher.qml` replaces labwc's window switcher, which can show previews
too, but in its own layout: a grey selection, the icon drawn over the
preview, padding off the grid. labwc binds Alt+Tab and Alt+Shift+Tab to
`qs ipc call switcher next`/`previous` (about 35 ms); the switcher takes
the keyboard and goes to the picked window when Alt comes up. Windows are
ordered by use, tracked from each toplevel's `activated`.

- **Previews**: Quickshell's ScreencopyView only captures single windows
  through Hyprland's protocol, so they're taken with `grim -T <identifier>`
  (ext-image-copy-capture, uncompressed PPM at full size, scaled down once
  as it loads with `sourceSize`, which smooths where drawing it smaller or
  grim's own `-s` only sample, so text came out jagged). labwc captures all of a window's
  surfaces, and Firefox keeps one above and left of its window, so its
  capture was 1480 x 1172 for a 1280 x 972 window, the rest pure black;
  `puter-windows trim` cuts pure-black (#000000) edge rows and columns off
  each capture, which no window's whole edge is (puter's ink is #060606), every window
  at once as it opens and four times a second while it's up. The
  identifiers come from ext-foreign-toplevel-list, which Quickshell doesn't
  expose; `src/windows` (`puter-windows`) lists them with app ID and title,
  and the switcher matches those to its own windows. They're written to two
  files in turn (A and B) and loaded synchronously, so a new frame never
  shows half-written or leaves a gap.
- **Alt let go**: a real keyboard sends Alt's release to whatever has the
  keyboard by then, even when Alt went down before. The switcher's surface
  stays mapped while closed (empty, with an empty input mask) so getting
  the keyboard is only a focus change; a tap quicker than that (IPC and a
  frame) would leave it open, but taps at 30 ms in testing didn't. Any key
  released without Alt held picks too.
- **Quick taps**: the cards show only after 120 ms (or a second Tab), so
  Alt+Tab tapped goes back to the last window without a flash.
- **Testing it**: `wtype -M alt` only sets the modifier state and sends no
  Alt key, so nothing ever sees Alt let go; `wtype -M alt -P Alt_L -k Tab
  -s 80 -p Alt_L -m alt` is a real tap.

## No passwords

puter is for workshops and machines with nothing sensitive on them, so,
like Kali's live images, nothing asks for a password. `install.sh access`
(the first thing a full install does) gives the user sudo with `NOPASSWD:
ALL` (`/etc/sudoers.d/10-puter`, checked with `visudo -c` before it's put in
place) and a polkit rule that allows them every action
(`/etc/polkit-1/rules.d/10-puter.rules`: Wi-Fi, disks, power), and greetd
starts labwc as them with no login screen, on boot and after logging out.
So anything that runs as the user can become root: fine for a workshop
machine, not for one with your own data on it.

## Updates

`bin/puter-update` brings everything to the newest, in steps: Arch (the
keyring first, then `pacman -Su` with whatever `packages.txt` has gained,
and `paccache -rk2`), firmware (fwupd), puter itself (`git pull --ff-only`,
when the checkout has a remote), the four packages in `packages/`, puter's
apps from `src/` (always rebuilt: a Qt upgrade breaks the style plugin),
Claude Code (`claude update`), and `install.sh config`. It runs as root
through sudo, and runs as the user (`runuser`) what mustn't be root:
makepkg, the builds, git, Claude Code, the settings. A failed step is
reported and the rest still run, except when Arch's own upgrade fails.

The recipes follow upstream rather than waiting to be bumped by hand: labwc
to Arch's version (still patched, a release above Arch's so pacman never
swaps it back; `pacman -Su` ignores the four), wlrctl and qpdfview to the
AUR's, with the AUR recipe's checksums (read with a regex, never sourced),
and JLCONE to JLCPCB's own electron-updater feed (`latest-linux.yml`), whose
sha512 is the checksum. A bumped copy is built; the repo isn't changed, and
`install.sh` only rebuilds a package older than its recipe, so it doesn't
undo an update.

`puter-update check` lists what's out of date without root (`checkupdates`
from pacman-contrib, a copy of the sync database). `Updates.qml` runs it
each time it opens, then `sudo -n puter-update run`, reading `::step`,
`::fail`, `::restart` and `::done` lines; everything else is shown, a
line a module, and kept in `~/.local/state/puter/update.log`.
`::restart` comes when the kernel, systemd, glibc, mesa, Qt, wlroots, labwc
or Quickshell changed; the bar's button then turns orange and the panel's
button restarts.

## Things that took finding out

- **Carbon at 16px**: most icons are drawn on a 32px grid and halved, and
  Carbon centres them, so a line down the middle lands from 7.5 to 8.5, two
  gray pixels. `theme/make` hints each 16px glyph: it draws it nudged half a
  pixel four ways (`rsvg-convert`, read with PIL) and keeps the sharpest.
  Apps ask for a file type's own icon first (`text-x-log`, `image-png`), so
  `theme/icons.map` names the common ones, or Breeze's would show.
- **Window outlines** are labwc's 1px border in the `outline` role. Two
  snapped windows would show two lines side by side, and labwc has no setting
  for it: `packages/labwc` is Arch's recipe plus `snap.patch`, which makes a
  snapped window reach one border further right and down, so its borders lie
  on its neighbour's and under the taskbar's top line, and one border further
  out against the screen's left and top edges, so no border lines the screen.
  Installing a new labwc takes a session restart to show.
- **Qt's SVG renderer (SVG Tiny)** draws a `clipPath` as a filled black
  square, so the icon theme uses none (Carbon's are plain paths and
  circles). Icons the theme doesn't name come from Breeze, whose icons Qt draws as they are (Adwaita's are symbolic outlines
  only GTK can recolour).
- **Qt stylesheets and sizes**: a widget the stylesheet gives a border or
  background is sized from the stylesheet's box model, ignoring the widget
  style, and tool buttons get 3px more than that; a border on a toolbar
  becomes a frame on every side. Hence heights pinned in the stylesheet, the
  toolbar's rule painted as a gradient, and frames, margins and layout spacing
  taken away in `src/style`.
- **Qt apps save their settings when they quit**, over anything written to
  their ini files meanwhile: close them before `dev/sync`.
- **FeatherPad** keeps its syntax colours in `fp_light_syntax_colors.conf`:
  exactly eleven keys, each a different colour, or it throws the file away.
  It paints its line-number gutter dark gray in code, so line numbers are off.
- **PCManFM-Qt's path bar** is `Fm::PathBar`, `Fm--PathBar` in a stylesheet.
- **QML `Item` already has `top`, `left`, `right` and `bottom`** (anchor
  lines, FINAL): a property of that name breaks the whole shell, silently, on
  reload. Outline's sides are `edgeTop` and so on.
- **Qt text** takes subpixel smoothing from the display, not fontconfig; the
  shell's text uses `Text.CurveRendering` to stay in grays.
- **`Palette` is a built-in QML type**, so the generated colours singleton is
  `Colors.qml`.
- **labwc draws `*_hover` button images instead of its hover colour**, so
  hover is drawn into those images.
- **Quickshell and labwc keep every icon they've looked up** for as long as
  they run, misses included: an app whose square is added while the shell
  runs shows no square on its taskbar tab until the shell starts again. A
  login always has them; `dev/sync` restarts the shell when `theme/icons`
  changed.
- **Quickshell deletes its desktop entries when it rescans** (an app
  installed, a desktop file rewritten): holding one (search's recent apps,
  from `DesktopEntries.byId`) crashed the shell the next time search opened.
  Search finds them again among the apps, so they're looked up afresh.
- **Thunderbird's about:3pane and about:message** take the profile's
  userChrome.css too. Its panes are a grid sized by variables on their
  `<body>` (`--folderPaneSplitter-width`, `--messagePaneSplitter-width`),
  the window's content is moved in by `--spaces-total-width` unless the
  spaces column is really hidden, the list header draws a second rule as
  `thead::after`, and Gecko draws a grey 1px line along the window's top
  that nothing names (the toolbox is lifted over it).
- **Window rules size apps that keep their own size** (`rc.xml`): labwc's
  `ResizeTo` when a window first maps, only for `type="normal"` (else their
  dialogs are blown up too). qpdfview's app ID is `qpdfview.local.qpdfview`.
- **qpdfview only draws its page edge and background with
  `decoratePages`** (otherwise the background is the paper colour, so pages
  vanish); the decoration is a 1px edge, no shadow.
- **qps's fields are numbered by its build** (`proc.h` less the fields it
  leaves out): 47 the command, 42 processor, 32 memory; 48 crashes it.
- **A desktop file without a name doesn't count**: the system's copy shows
  instead. Hiding an app (`NoDisplay=true`) keeps its name.
- **Quickshell reads the app folders it finds at start**: one made later
  (`~/.local/share/applications`, on a desktop already running) shows in
  search only after the shell restarts.
- **foot reads its font as fontconfig does**, so `puter-mono` would be the
  family puter at size mono: `theme/make` writes the family's own name.
- **Without a GPU** (only in the VM), wlroots crashes on native-Wayland OpenGL
  apps: see `dev/devbox/README.md` for the workarounds.
- **At rest** (`dev/idle`, VM, 21 October): every process 0.0% CPU over a
  minute, with nothing open and with every app open (the system 0.01-0.02%
  busy). Memory (PSS) with nothing open, about 213 MB in all: Quickshell
  116, labwc 38, the portals 21, PipeWire and WirePlumber 16, gvfs 14
  (PCManFM's trash and drives), the accessibility bus 3. Every app open adds
  about 410 MB: qutebrowser about 350 with its web processes, each Qt app
  14-18. Quickshell is about 120 MB however it's tuned (malloc arenas, the
  QML interpreter): its heap and Qt. The desk's dots are a tiled module
  image, not a full-screen canvas; the GTK portal is gone (it only served
  desktop settings, asked for at login, 16 MB); the activity chart samples
  only while settings was open (since removed).

## Working on it

Edit on the Mac in `~/Desktop/puter`, then:

- `dev/sync`: copy to the VM, run `install.sh config`, reload labwc
  (Quickshell reloads itself).
- `dev/shot`: screenshot to `dev/shots/shot.png`.
- `dev/idle`: CPU and memory per process at rest, with nothing open and with
  every app open.
- `dev/grid`: check a screenshot against the grid (every window's edges,
  from its own corner); `dev/tour`: open every app and dialog and check each,
  into `dev/shots/tour/`. A step is an app and the keys that open a window.
- `dev/click X Y`, `dev/run CMD`: click and launch on the VM's desktop.
- `dev/screen`: use the desktop live in Screen Sharing; `dev/screen stop`.

Start the VM first: `ssh server ~/archvm/up.sh`.
