# Next

Where things stood at the end of the 20 October 2026 session.

## Asked for, not done yet

- **Settings as a 2x2 square.** Mirror the search square: a 60x60 ink square
  in the bottom-right corner with the sliders glyph, the clock moved to its
  left on the strip, and the settings panel standing on the square, flush right
  (`margins.bottom: Theme.module * 2`). The bar's input `mask` needs the new
  square added, as the search square is.

## Open edges

- **The grid in dialogs** (20-21 October): every Qt dialog is laid out by
  the style; `dev/tour` passes 9 of its 17 windows, and most of the rest
  look right but trip the checker. Left: Falkon (its preferences, 43 off,
  and its own tab bar), the About box's icon, PCManFM's file properties
  (the icon button), message boxes' colour Breeze icons (the question mark),
  QTerminal's colour scheme showing as BlackOnLightYellow in its settings.
- **dev/grid** finds a dialog by what changed on screen (`--before`), which
  misjudges an edge lying over black that was there before, or content
  changing inside the dialog.

- **The file dialog** (libfm-qt's, through LXQt's portal) is the same for
  FeatherPad, Falkon and GTK 3 apps that ask for a native dialog, pared down
  and measured onto the grid (path bar, list, one strip of name and
  buttons). JLCONE's (Electron) hasn't been opened yet. Where it opens isn't
  on the grid: labwc centres dialogs over their window, and floating windows
  generally land wherever they're placed (FeatherPad's title bar at y=260).

- **The Qt apps, measured and not.** PCManFM-Qt, FeatherPad and Sheet are
  measured onto the grid (bars, tabs, headers, rows). LXImage-Qt, Falkon and
  QTerminal take the style but haven't been measured, and no dialog has been
  looked at yet (Qt's own file dialog, preferences windows). Falkon's tab bar
  is its own widget.
- **Sheet** opens, edits, adds and removes rows and columns, undoes and
  saves. It has no find, sort or filter yet.
- **FeatherPad's line numbers** are off: it paints their gutter dark gray in
  code.
- **Wi-Fi in settings** is untested: the VM has no Wi-Fi. Connecting only
  works for open and already-saved networks; there's no password prompt yet.
- **The power buttons** in settings haven't been pressed.
- **The login screen step** of `install.sh` (greetd + tuigreet) is untested:
  the VM uses its own auto-login.
- **The search square overlaps windows**: windows stop at the strip (one
  module), so a snapped window's bottom-left 60x30 sits under the square.
  Making windows stop above the square would waste a row along the bottom.
- KiCad, JLCONE (Electron, its own web UI) and other apps keep their
  own toolbar layouts and icons; only their GTK parts follow the theme.
- **Hover under scripted input**: right after `dev/click` on a taskbar tab,
  hover sometimes doesn't show until the pointer comes back from elsewhere.
  Not seen as a real problem, but untested with a real mouse.

## Ideas mentioned along the way

- Build search out further: files (plocate or fd), a calculator, commands.
- A GTK 3 theme check for KiCad's dialogs, footprint and symbol editors, and
  the 3D viewer (themed but not looked at).
- Light and dark versions of a palette.
