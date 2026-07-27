#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

stub_bin="$tmp/bin"
mkdir "$stub_bin"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$@" >> "$PCT_LOG"\n' > "$stub_bin/pct"
chmod +x "$stub_bin/pct"

PATH="$stub_bin:$PATH" PCT_LOG="$tmp/pct.log" \
  "$repo_root/scripts/bootstrap/proxmox-lxc-create.sh" \
  /var/lib/vz/template/cache/nixos-system-x86_64-linux.tar.xz

test "$(cat "$tmp/pct.log")" = "$(cat <<EOF
create
200
local:vztmpl/nixos-system-x86_64-linux.tar.xz
--hostname
vasher
--cores
4
--memory
12288
--swap
2048
--rootfs
local-lvm:100
--net0
name=eth0,bridge=vmbr0,ip=dhcp
--features
nesting=1
--unprivileged
1
--ssh-public-keys
$HOME/.ssh/authorized_keys
start
200
EOF
)"

settings=$(nix eval "$repo_root#nixosConfigurations.vasher.config.nix.settings" --json)
test "$(jq -r '."max-jobs"' <<<"$settings")" = 1
test "$(jq -r '.cores' <<<"$settings")" = 4
