# Next

Where things stood at the end of the 20 October 2026 session.

## Asked for, not done yet

- **Settings as a 2x2 square.** Mirror the search square: a 60x60 ink square
  in the bottom-right corner with the sliders glyph, the clock moved to its
  left on the strip, and the settings panel standing on the square, flush right
  (`margins.bottom: Theme.module * 2`). The bar's input `mask` needs the new
  square added, as the search square is.
- **Mousepad's lines on the grid.** Lines are 20px (Geist Mono 11pt); they and
  their line numbers should be 30. Neither Mousepad nor GTK 3 has a setting, so
  patch it like Thunar: `packages/mousepad` from Arch's PKGBUILD
  (`gitlab.archlinux.org/archlinux/packaging/packages/mousepad`, meson build),
  with a `prepare()` that adds to `mousepad_view_init` in
  `mousepad/mousepad-view.c`:
  `gtk_text_view_set_pixels_above_lines (GTK_TEXT_VIEW (view), 5);` and
  `gtk_text_view_set_pixels_below_lines (GTK_TEXT_VIEW (view), 5);`
  then build it from `install.sh` the way Thunar is, and measure that line 1
  sits at 90 to 120 under the tabs.

## Open edges

- **Wi-Fi in settings** is untested: the VM has no Wi-Fi. Connecting only
  works for open and already-saved networks; there's no password prompt yet.
- **The power buttons** in settings haven't been pressed.
- **The login screen step** of `install.sh` (greetd + tuigreet) is untested:
  the VM uses its own auto-login.
- **The search square overlaps windows**: windows stop at the strip (one
  module), so a snapped window's bottom-left 60x30 sits under the square.
  Making windows stop above the square would waste a row along the bottom.
- **Mousepad and code lines** aside, KiCad, Chromium and other apps keep their
  own toolbar layouts and icons; only their GTK parts follow the theme.
- **Hover under scripted input**: right after `dev/click` on a taskbar tab,
  hover sometimes doesn't show until the pointer comes back from elsewhere.
  Not seen as a real problem, but untested with a real mouse.

## Ideas mentioned along the way

- Build search out further: files (plocate or fd), a calculator, commands.
- A GTK 3 theme check for KiCad's dialogs, footprint and symbol editors, and
  the 3D viewer (themed but not looked at).
- Light and dark versions of a palette.
