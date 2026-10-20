#!/bin/sh
# Arch dev VM. Started by ~/archvm/up.sh as a capped transient unit, so CI always wins.
# Reachable only from the devbox itself: ssh on 127.0.0.1:2222, VNC on 127.0.0.1:5900.
cd "$(dirname "$0")"
exec qemu-system-x86_64 -enable-kvm -machine q35 -cpu host -smp 6 -m 8G \
  -drive file=arch.qcow2,if=virtio,cache=writeback,discard=unmap \
  -drive file=seed.iso,media=cdrom,readonly=on \
  -nic user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:2222-:22 \
  -device virtio-vga,xres=1920,yres=1080 \
  -object secret,id=vncpw,file=vnc-password \
  -vnc 127.0.0.1:0,password-secret=vncpw \
  -device virtio-tablet-pci -device virtio-keyboard-pci \
  -audiodev none,id=snd0 -device ich9-intel-hda -device hda-output,audiodev=snd0 \
  -serial file:serial.log
