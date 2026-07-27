#!/usr/bin/env bash
set -euo pipefail

image=${1:?usage: $0 /var/lib/vz/template/cache/nixos-system-x86_64-linux.tar.xz}
pct create 200 "local:vztmpl/$(basename "$image")" \
  --hostname vasher --cores 4 --memory 12288 --swap 2048 --rootfs local-lvm:100 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp --features nesting=1 \
  --unprivileged 1 --ssh-public-keys ~/.ssh/authorized_keys
pct start 200
