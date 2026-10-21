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
| Web | Firefox | A normal browser (tabs, an address field), its whole interface restyled by one stylesheet (`theme/firefox`, from the palette) and its settings a web page |
| PCB orders | JLCONE | JLCPCB's Electron app, from their .deb (`packages/jlcone-bin`, the AUR's recipe) |
| Login | greetd + tuigreet | Text login that starts labwc |
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
