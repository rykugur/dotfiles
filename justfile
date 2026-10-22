set shell := ["bash", "-euo", "pipefail", "-c"]

pve_token := "$HOME/.config/pve/agent.token"
pve_url := "https://roshar.local.ryk.sh:8006"
tofu_dir := "infra/proxmox"

default:
  @just --list

# Create an LXC on roshar and let comin take it over from first boot.
lxc host node="roshar" memory="4096" disk="32" cores="2":
  PVE_API_TOKEN="$(cat {{pve_token}})" PVE_API_URL="{{pve_url}}" \
  nix run .#pve-provision -- lxc {{host}} \
    --node {{node}} \
    --build .#{{host}}-lxc-image \
    --cores {{cores}} --memory {{memory}} --disk {{disk}} \
    --age-key-sops modules/hosts/{{host}}/age-key.sops

# Same, but only prints what would be created.
lxc-dry host node="roshar":
  PVE_API_TOKEN="$(cat {{pve_token}})" PVE_API_URL="{{pve_url}}" \
  nix run .#pve-provision -- lxc {{host}} --node {{node}} \
    --build .#{{host}}-lxc-image --dry-run

# Destroy a guest. Refuses anything outside pool `agent-managed`.
destroy vmid:
  PVE_API_TOKEN="$(cat {{pve_token}})" PVE_API_URL="{{pve_url}}" \
  nix run .#pve-provision -- destroy {{vmid}} --force-stop

# Create the nale VM and install NixOS onto it, headless end to end.
vm-install host="nale":
  #!/usr/bin/env bash
  set -euo pipefail
  umask 077
  export PROXMOX_VE_API_TOKEN="$(cat {{pve_token}})"
  iso="$(nix build --no-link --print-out-paths .#{{host}}-installer-iso)/iso/{{host}}-installer.iso"

  tofu -chdir={{tofu_dir}} init -input=false
  if tofu -chdir={{tofu_dir}} state show proxmox_virtual_environment_vm.nale >/dev/null 2>&1; then
    echo "nale already managed by OpenTofu; refusing to reinstall its disk" >&2
    exit 1
  fi
  tofu -chdir={{tofu_dir}} apply -auto-approve -input=false \
    -var="installer_iso_path=$iso" -var="boot_from_disk=false"

  echo "waiting for the installer to report an address"
  for _ in $(seq 1 60); do
    ip="$(tofu -chdir={{tofu_dir}} output -json {{host}}_ipv4 \
      | jq -r 'flatten | map(select(. != "127.0.0.1" and . != "")) | first // empty')"
    [[ -n "$ip" ]] && break
    sleep 5
    tofu -chdir={{tofu_dir}} refresh -input=false -var="installer_iso_path=$iso" >/dev/null
  done
  [[ -n "${ip:-}" ]] || { echo "no address from the guest agent" >&2; exit 1; }
  echo "installer at $ip"

  # The host's sops identity rides along in tmpfs so sops-nix can decrypt on
  # first boot; it never touches disk on this machine.
  extra="$(mktemp -d -p /dev/shm)"
  ssh_hosts="$(mktemp -p /dev/shm)"
  trap 'find "$extra" -type f -exec shred -u {} +; rm -rf "$extra"; rm -f "$ssh_hosts"' EXIT
  install -d -m 700 "$extra/var/lib/sops-nix"
  sops -d --input-type binary --output-type binary \
    modules/hosts/{{host}}/age-key.sops > "$extra/var/lib/sops-nix/key.txt"
  chmod 600 "$extra/var/lib/sops-nix/key.txt"

  nixos-anywhere --flake .#{{host}} \
    --phases disko,install \
    --ssh-option "UserKnownHostsFile=$ssh_hosts" \
    --ssh-option StrictHostKeyChecking=accept-new \
    --extra-files "$extra" --chown /var/lib/sops-nix 0:0 \
    "root@$ip"

  # Detach the installer so the VM boots what disko just wrote.
  tofu -chdir={{tofu_dir}} apply -auto-approve -input=false \
    -var="installer_iso_path=$iso" -var="boot_from_disk=true"

  # Switching boot order does not guarantee that PVE reboots an already-running
  # installer. Reboot explicitly only after the ISO has been ejected.
  printf 'header = "Authorization: PVEAPIToken=%s"\n' "$PROXMOX_VE_API_TOKEN" |
    curl -fsS --config - -X POST "{{pve_url}}/api2/json/nodes/roshar/qemu/120/status/reboot" |
    jq -r '.data'

  for _ in $(seq 1 60); do
    if ssh -o BatchMode=yes -o ConnectTimeout=5 \
      -o "UserKnownHostsFile=$ssh_hosts" -o StrictHostKeyChecking=accept-new \
      "root@{{host}}.local.ryk.sh" \
      'test "$(findmnt -n -o FSTYPE /)" = btrfs && systemctl is-active --quiet comin' \
      >/dev/null 2>&1; then
      echo "{{host}} booted NixOS from disk; comin active"
      exit 0
    fi
    sleep 5
  done
  echo "{{host}} did not boot the installed system" >&2
  exit 1

# What each comin host is running right now.
comin-status +hosts:
  #!/usr/bin/env bash
  set -euo pipefail
  for h in {{hosts}}; do
    echo "== $h"
    ssh "$h.local.ryk.sh" 'systemctl is-active comin; comin status --oneline || true; readlink /run/current-system'
  done
