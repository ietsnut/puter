# puter

You are running on puter: Arch Linux with labwc (a Wayland compositor) and
a Quickshell bar, every app themed from one palette onto a 30px grid. The
user's setup lives in ~/puter (a git checkout); its README says how it fits
together.

## Every change goes into ~/puter

Every puter is built from ~/puter alone, so anything done here has to be
done there, or it's lost on the next machine and undone by the next update.

- Programs: add or remove them in `packages.txt`, then run `sudo
  bin/puter-update` (or `pacman -S` the same names). Never install with
  pacman, pip, npm, cargo or curl without listing it; removing a line is
  how a program is uninstalled everywhere.
- Settings: a config folder or file in `config/` (linked into `~/.config`),
  or written by `install.sh config` for apps that rewrite their own
  settings. Then run `install.sh config`. Colours, fonts and icons come
  from `theme/` (`theme/make`).
- Commit and push when it works; every puter picks it up with its next
  update.
- Secrets go in encrypted: API keys and tokens for puter's tools go in
  `secrets.age` with `bin/puter-secret set NAME value` (tools read them with
  `puter-secret get NAME`); never as plain text in the repo, which is public.
  The key that opens them is only on the machines (`~/.config/puter/age.key`).
  Logins that apps keep themselves (`~/.config/gh`, Wi-Fi passwords) stay on
  the machine.

## The desktop

The `puter` MCP server lets you see and use the screen: `screenshot`,
`windows`, `focus`, `click`, `move`, `scroll`, `type`, `key` and `open`.
Points are screenshot pixels. Take a screenshot before you act and after,
to see what happened. Use the shell for anything the shell can do; the
desktop is for apps with no other way in.

Ask before you close windows, send or submit anything, or change settings.
