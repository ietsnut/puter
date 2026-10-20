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

## The stack

| Part | What | Why |
| --- | --- | --- |
| Compositor | labwc | Floating by design, light, Raspberry Pi OS's default so ordinary apps are well tested on it; runs without a GPU |
| Shell | Quickshell (QML) | Desk, bottom bar, search, settings drawn exactly to the grid; reloads live |
| Terminal | ghostty | Geist Mono |
| Files | Thunar (patched) | Kept after considering a Quickshell-built one, yazi and PCManFM |
| Text and code | Mousepad | GTK 3, GtkSourceView syntax colours from the palette |
| Photos, video | imv, mpv | No interface of their own |
| Web | Chromium | |
| Login | greetd + tuigreet | Text login that starts labwc |
| Fonts | Geist, Geist Mono | Geist from the AUR (built by `install.sh`), Geist Mono Nerd from extra |

Tried and dropped: Hyprland, niri and sway (tiling), KDE Plasma (heavy, its
own look), Wayfire, waybar, fuzzel, swaybg, Docker previews on the Mac, a
black/white/gray palette, dithering, pixel-art icons.

## How the look is made

- `theme/palettes/<name>` assigns a palette's colours to every role: the
  interface (desk, paper, ink, accent, muted, hover), syntax, the terminal's
  sixteen ANSI colours, KiCad's board/schematic/3D colours. `theme/palette`
  names the one in use: `pico-8` now, `apollo` also available.
- `theme/make` writes everything from it: `quickshell/Colors.qml`, labwc's
  `themerc` and window buttons (with hover images), the icon theme, the GTK
  colours, the GtkSourceView scheme, ghostty, imv, mpv, and KiCad's theme.
  Generated files say so at the top; edit the palette, not them.
- `quickshell/Theme.qml` holds the geometry (module 30, inset 8, Geist 15px).
- `theme/gtk-3.0/gtk.css` restyles Adwaita for GTK 3 apps. Most of it is
  overriding Adwaita rules that are more specific than a plain selector; the
  `:not(.puter-a):not(.puter-b)` selectors exist only to outrank them.
- `install.sh config` links the folders into `~/.config`, the theme and icons
  into `~/.local/share`, and applies gsettings (GTK reads its theme from
  gsettings on Wayland, not settings.ini), xfconf (Thunar) and KiCad settings.

## Things that took finding out

- **Adwaita's hidden spacing.** Toolbar items get a 1px right and bottom
  margin from `toolbar:not(.inline-toolbar):not(.osd) > *:not(.toggle):not(.popup) > *`;
  tab close buttons are shrunk to 20px and dimmed to 30%; flat buttons, frames
  and notebooks carry borders. All overridden in `gtk.css`.
- **Measuring GTK.** `python-gobject` test windows in the VM print exact
  allocations and computed CSS (`get_preferred_width`, `get_margin`); the GTK
  inspector (`GTK_DEBUG=interactive`) works but is slow to drive remotely.
- **Thunar** pads its sidebar headings 4px more than its rows in code, so the
  side pane is hidden (F9 shows it) and the list view is the default. Its path
  field had 5px margins and an icon in code: `packages/thunar` is Arch's
  recipe with both removed, built by `install.sh`. When Arch updates Thunar,
  copy their PKGBUILD in again and keep the `prepare()` changes.
- **Mousepad** packs its tabs with 2px of padding in code; its notebook takes
  it back with a -2px CSS margin (GTK 3 applies CSS margins to notebooks, not
  to plain containers).
- **Qt text** takes subpixel smoothing from the display, not fontconfig; the
  shell's text uses `Text.CurveRendering` to stay in grays.
- **`Palette` is a built-in QML type**, so the generated colours singleton is
  `Colors.qml`.
- **labwc draws `*_hover` button images instead of its hover colour**, so
  hover is drawn into those images.
- **Without a GPU** (only in the VM), wlroots crashes on native-Wayland OpenGL
  apps: see `dev/devbox/README.md` for the workarounds.

## Working on it

Edit on the Mac in `~/Desktop/puter`, then:

- `dev/sync`: copy to the VM, run `install.sh config`, reload labwc
  (Quickshell reloads itself).
- `dev/shot`: screenshot to `dev/shot.png`; crop and measure with PIL.
- `dev/click X Y`, `dev/run CMD`: click and launch on the VM's desktop.
- `dev/screen`: use the desktop live in Screen Sharing; `dev/screen stop`.

Start the VM first: `ssh server ~/archvm/up.sh`.
