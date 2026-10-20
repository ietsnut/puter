# The dev VM on the devbox

puter is developed in an Arch VM on the devbox (`ssh server`, the shared i9
machine that also runs the company's CI runners) and looked at through
screenshots or Screen Sharing from the Mac. Nothing here goes onto a real puter
install; it only makes the VM work.

## Rules for the devbox

- The only host changes are the qemu packages (`qemu-system-x86`,
  `qemu-system-modules-opengl`, `qemu-utils`). GPU libraries were tried and
  removed again at the user's request; the VM renders in software.
- Everything else lives in `~/archvm` on the devbox: `arch.qcow2` (the disk),
  `seed.iso` (cloud-init), `vnc-password`, and the three scripts copied here.
- The VM runs as a transient systemd unit at low priority so CI always wins:
  CPU weight 10, IO weight 10, 6 cores, 10 GB at most. Nothing is installed as
  a service, so it doesn't start on its own.
- The devbox suspends after 15 minutes without a CI job or an SSH connection
  (`/usr/local/bin/idle-suspend.sh`, theirs, not ours). An open `ssh` or
  `dev/screen` tunnel keeps it awake; a suspended devbox freezes the VM, which
  carries on when it wakes.

## Starting and stopping

```
ssh server ~/archvm/up.sh      # start the VM (about 40 s to the desktop)
ssh server ~/archvm/down.sh    # stop it; or `ssh archvm sudo poweroff`
```

The Mac reaches the VM as `ssh archvm` (`~/.ssh/config`: 127.0.0.1:2222 via
`ProxyJump server`, user `ietsnut`, key `~/.ssh/id_ed25519`).

## How the VM was built

1. `qemu-img` on the official Arch cloud image
   (`geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2`,
   checksum verified), resized to 60 GB.
2. `seed.iso`: a cloud-init NoCloud seed, made on the Mac with
   `hdiutil makehybrid -iso -joliet -default-volume-name cidata`, holding
   `user-data` (user `ietsnut` in wheel/video/render/input, passwordless sudo,
   the Mac's SSH public key, growpart) and `meta-data` (hostname `archvm`).
3. `run.sh`: q35, KVM, `-cpu host`, 6 cores, 8 GB, virtio disk and network
   (user networking, SSH forwarded to 127.0.0.1:2222), `virtio-vga` at
   1920x1080 without 3D, VNC on 127.0.0.1:5900 behind `vnc-password`, a
   tablet for absolute pointer input, and a silent HDA sound card so PipeWire
   has a sink.
4. In the VM: puter's packages (`./install.sh packages`), its configs
   (`./install.sh config`), plus `rsync` (for `dev/sync`), `wtype` and
   `wlrctl` (AUR; typing and clicking for `dev/click`), `python-gobject` (GTK
   probes), `xorg-xwayland`, `kicad`, the PipeWire user services enabled.
5. VM-only settings, not part of puter:
   - `vm-greetd.toml` is the VM's `/etc/greetd/config.toml`: log straight into
     labwc, with `WLR_RENDERER=pixman LIBGL_ALWAYS_SOFTWARE=1`. Without a GPU,
     wlroots crashes on native-Wayland OpenGL apps; this and XWayland avoid it.
   - `switch-to-nm` moved the VM from systemd-networkd to NetworkManager (what
     puter uses), reverting itself if that lost the network.
   - Apps that need OpenGL run differently in the VM: KiCad through XWayland
     (`dev/run env GDK_BACKEND=x11 kicad`), mpv with `--vo=wlshm`, Chromium
     with `--disable-gpu`. None of this is needed on real hardware.
6. Test material in the VM: `~/kicad-demos/pic_programmer` (from KiCad's
   source), `~/samples` (`notes.md`, `grid.py`, `photo.png`, `clip.mp4`).

## Removing it all

```
ssh server 'sudo systemctl stop archvm; rm -rf ~/archvm'
ssh server 'sudo apt-get purge qemu-system-x86 qemu-system-modules-opengl qemu-utils && sudo apt-get autoremove'
```

and remove the `Host archvm` block from the Mac's `~/.ssh/config` and
`~/.ssh/known_hosts_archvm`.
