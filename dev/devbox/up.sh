#!/bin/sh
# Start the VM: a low CPU and IO weight so runner jobs take precedence, capped at
# 6 cores and 10 GB. Transient: nothing is written to the host system config.
sudo systemd-run --unit=archvm --uid=ietsnut --gid=ietsnut \
  -p SupplementaryGroups="kvm render" \
  -p CPUWeight=10 -p IOWeight=10 -p CPUQuota=600% -p MemoryMax=10G -p Nice=10 \
  "$HOME/archvm/run.sh"
