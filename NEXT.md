# Next

Where things stood at the end of the 20 October 2026 session.

## Open edges

- **Mail with a real account** (21 October): the main window, folders,
  list, message and the account hub are styled and measured with local
  mail, but no account has been signed in, so the compose window, account
  settings and Thunderbird's settings tab haven't been seen yet; the
  account central page (an account's own page) keeps its watermark.

- **The agents, signed in** (21 October): the windows, search, the folder
  menu, the tab states (driven by hand over IPC and through `puter-agent
  hook`) and `puter-desktop` (over stdio, and Claude Code's `mcp list`) are
  tested, but not a signed-in session: that the hooks fire as expected
  (Claude Code's PermissionRequest, Codex trusting them), and an agent
  actually driving the desktop through the `puter` tools.

- **The grid in dialogs** (20-21 October): every Qt dialog is laid out by
  the style; `dev/tour` passes 9 of its 17 windows, and most of the rest
  look right but trip the checker. Left: the About box's icon, PCManFM's file properties
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
- **Wi-Fi** is untested: the VM has none (nmtui, from the network glyph). Connecting only
  works for open and already-saved networks; there's no password prompt yet.
- **Restart and shut down** in the bar haven't been pressed.
- **Updates** (21 October) ran end to end on the VM, but with nothing to
  bump: a recipe
  rebuilt (forced) and bumped copies' checksums verified, not a real new
  labwc with the patch applied to it. Firmware is untested on hardware.
- **Alt+Tab** (21 October): tested on the VM with wtype (taps down to
  30 ms, holding and stepping, letting go); not yet with a real keyboard,
  nor with many windows (two rows) or minimised ones (grim can't capture a
  window that isn't drawn; its card shows the last preview, or none).
- **No passwords** (21 October): `install.sh access` (sudo and polkit) is
  tested on the VM; the greetd part (labwc straight away, no login screen)
  isn't, since the VM keeps its own greetd config (pixman rendering).
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
