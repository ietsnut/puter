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
- **Clean vector icons, 2px strokes.** No pixel art, no dithering. Glyphs sit
  in a 10x10 box (14px in toolbars), straight lines on whole pixels so they're
  sharp, diagonals and curves smooth.
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
| Files | PCManFM-Qt | |
| Text and code | FeatherPad | |
| Tables | Sheet (`qt/sheet`, puter's own) | No maintained small Qt table editor exists |
| Photos | LXImage-Qt | |
| Video | mpv | No interface of its own |
| Web | Falkon | Qt Widgets chrome (styled like every other app) on Chromium's engine |
| PCB orders | JLCONE | JLCPCB's Electron app, from their .deb (`packages/jlcone-bin`, the AUR's recipe) |
| Login | greetd + tuigreet | Text login that starts labwc |
| Fonts | IBM Plex Sans, IBM Plex Mono | The dental desk's and its reports' font; `ttf-ibm-plex` from extra |

Tried and dropped: Hyprland, niri and sway (tiling), KDE Plasma (heavy, its
own look), Wayfire, waybar, fuzzel, swaybg, Docker previews on the Mac,
dithering, pixel-art icons, the PICO-8 and Apollo palettes and Geist (replaced
by the Mulholland look, 20 October 2026), Gnumeric, Apostrophe, Chromium.
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
- `theme/make` writes everything from it: `quickshell/Colors.qml`, labwc's
  `themerc` and window buttons (with hover images), the icon theme, the GTK 3
  colours (KiCad), the Qt stylesheet and palette (`qt6ct/`), FeatherPad's
  syntax colours, QTerminal's colours, and KiCad's theme. Generated files say
  so at the top; edit the palette, not them.
- **Qt apps** are styled in two parts, both read through qt6ct
  (`QT_QPA_PLATFORMTHEME` in `labwc/environment`):
  - `qt/style` is puter's widget style, a plugin on Fusion: it takes away the
    frames, margins and layout spacing Qt keeps around bars and menus (in main
    windows; dialogs keep theirs), sets 16px icons, and table rows of 30 and
    columns of 150. A stylesheet can't reach these.
  - `theme/qt/puter.qss` is the stylesheet: colours, outlines and rules, and
    the heights that pin each widget it styles to the 30px module. Qt sizes a
    widget from the stylesheet as soon as it gives it a border or background
    and adds a few pixels of its own, so heights are pinned (`min-height` and
    `max-height`, or `height`), not padded.
- **File dialogs** come from one place for every app: LXQt's portal, whose
  dialog is libfm-qt's (PCManFM-Qt's own, so styled like any Qt window).
  Qt apps reach it through qt6ct (`standard_dialogs=xdgdesktopportal`), GTK 3
  apps and Electron through `GTK_USE_PORTAL`, GTK 4 and Flatpaks by default;
  `xdg-desktop-portal/labwc-portals.conf` routes it. GTK 3 apps that build
  their own dialog rather than asking for a native one (wxWidgets, so KiCad)
  still show GTK's. The portal's systemd service sets
  `QT_QPA_PLATFORMTHEME=lxqt`; `systemd/` overrides it with qt6ct, or the
  dialog comes up in plain Fusion. The dialog is pared down in two places:
  `install.sh` writes `~/.config/lxqt/filedialog.conf` (list view, name,
  size and date, 720x480), and `qt/style` takes away its side pane, toolbar
  (keeping its shortcuts), labels and margins, finding them by the names in
  libfm-qt's `filedialog.ui`; the file type row only shows with a choice of
  types.
- `quickshell/Theme.qml` holds the geometry (module 30, inset 8, IBM Plex Sans
  15px).
- `theme/gtk-3.0/gtk.css` restyles Adwaita for the GTK 3 apps that remain
  (KiCad). Most of it is overriding Adwaita rules that are more specific than
  a plain selector; the `:not(.puter-a):not(.puter-b)` selectors exist only to
  outrank them.
- `install.sh config` links the folders into `~/.config`, the theme and icons
  into `~/.local/share`, writes qt6ct's settings, sets the Qt apps' own
  options (FeatherPad, PCManFM-Qt, QTerminal) in their ini files, and applies
  gsettings (GTK reads its theme from gsettings on Wayland) and KiCad's.

## Things that took finding out

- **Window outlines** are labwc's 1px border in the `outline` role. Two
  snapped windows would show two lines side by side, and labwc has no setting
  for it: `packages/labwc` is Arch's recipe plus `snap.patch`, which makes a
  snapped window reach one border further right and down, so its borders lie
  on its neighbour's and under the taskbar's top line, and one border further
  out against the screen's left and top edges, so no border lines the screen.
  Installing a new labwc takes a session restart to show.
- **Qt's SVG renderer (SVG Tiny)** draws a `clipPath` as a filled black
  square, so the icon theme uses none. Icons the theme doesn't draw come from
  Breeze, whose icons Qt draws as they are (Adwaita's are symbolic outlines
  only GTK can recolour).
- **Qt stylesheets and sizes**: a widget the stylesheet gives a border or
  background is sized from the stylesheet's box model, ignoring the widget
  style, and tool buttons get 3px more than that; a border on a toolbar
  becomes a frame on every side. Hence heights pinned in the stylesheet, the
  toolbar's rule painted as a gradient, and frames, margins and layout spacing
  taken away in `qt/style`.
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
- **Without a GPU** (only in the VM), wlroots crashes on native-Wayland OpenGL
  apps: see `dev/devbox/README.md` for the workarounds.
- **Memory** (VM, PSS): labwc ~30-80 MB, Quickshell ~80-100 MB with the
  software renderer (335 MB through OpenGL without a GPU), Qt Widgets apps
  about 20-40 MB each, where the GTK 4 ones were 100-230 MB.

## Working on it

Edit on the Mac in `~/Desktop/puter`, then:

- `dev/sync`: copy to the VM, run `install.sh config`, reload labwc
  (Quickshell reloads itself).
- `dev/shot`: screenshot to `dev/shot.png`; crop and measure with PIL.
- `dev/click X Y`, `dev/run CMD`: click and launch on the VM's desktop.
- `dev/screen`: use the desktop live in Screen Sharing; `dev/screen stop`.

Start the VM first: `ssh server ~/archvm/up.sh`.
