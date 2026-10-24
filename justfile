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

# Create a VM and install NixOS onto it, headless end to end (nale, elantris, ...).
vm-install host:
  #!/usr/bin/env bash
  set -euo pipefail
  umask 077
  export PROXMOX_VE_API_TOKEN="$(cat {{pve_token}})"
  iso="$(nix build --no-link --print-out-paths .#{{host}}-installer-iso)/iso/{{host}}-installer.iso"

  # Hosts with a dedicated keypair (not Dusty's ambient default identity,
  # e.g. elantris) need it named explicitly, or every ssh attempt --
  # including nixos-anywhere's internal ssh-copy-id -- fails with
  # "Permission denied" against an installer that only trusts that key.
  identity="$HOME/.config/{{host}}/admin_ed25519"
  ssh_identity_opts=()
  plain_ssh_identity_opts=()
  if [[ -f "$identity" ]]; then
    ssh_identity_opts=(--ssh-option "IdentityFile=$identity" --ssh-option "IdentitiesOnly=yes")
    plain_ssh_identity_opts=(-o "IdentityFile=$identity" -o "IdentitiesOnly=yes")
  fi

  tofu -chdir={{tofu_dir}} init -input=false
  if tofu -chdir={{tofu_dir}} state show "proxmox_virtual_environment_vm.{{host}}" >/dev/null 2>&1; then
    echo "{{host}} already managed by OpenTofu; refusing to reinstall its disk" >&2
    exit 1
  fi
  tofu -chdir={{tofu_dir}} apply -auto-approve -input=false \
    -var="{{host}}_installer_iso_path=$iso" -var="{{host}}_boot_from_disk=false"

  echo "waiting for the installer to report an address"
  for _ in $(seq 1 60); do
    ip="$(tofu -chdir={{tofu_dir}} output -json {{host}}_ipv4 \
      | jq -r 'flatten | map(select(. != "127.0.0.1" and . != "")) | first // empty')"
    [[ -n "$ip" ]] && break
    sleep 5
    tofu -chdir={{tofu_dir}} refresh -input=false -var="{{host}}_installer_iso_path=$iso" >/dev/null
  done
  [[ -n "${ip:-}" ]] || { echo "no address from the guest agent" >&2; exit 1; }
  echo "installer at $ip"

  # Hosts without sops (rysn's persistence-only phase) need no extra files.
  ssh_hosts="$(mktemp -p /dev/shm)"
  trap 'rm -f "$ssh_hosts"' EXIT
  extra_opts=()
  if [[ -f "modules/hosts/{{host}}/age-key.sops" ]]; then
    extra="$(mktemp -d -p /dev/shm)"
    trap 'find "$extra" -type f -exec shred -u {} +; rm -rf "$extra"; rm -f "$ssh_hosts"' EXIT
    install -d -m 700 "$extra/var/lib/sops-nix"
    sops -d --input-type binary --output-type binary \
      modules/hosts/{{host}}/age-key.sops > "$extra/var/lib/sops-nix/key.txt"
    chmod 600 "$extra/var/lib/sops-nix/key.txt"
    extra_opts=(--extra-files "$extra" --chown /var/lib/sops-nix 0:0)
  fi

  nixos-anywhere --flake .#{{host}} \
    --phases disko,install \
    --ssh-option "UserKnownHostsFile=$ssh_hosts" \
    --ssh-option StrictHostKeyChecking=accept-new \
    "${ssh_identity_opts[@]}" \
    "${extra_opts[@]}" \
    "root@$ip"

  # Detach the installer so the VM boots what disko just wrote.
  tofu -chdir={{tofu_dir}} apply -auto-approve -input=false \
    -var="{{host}}_installer_iso_path=$iso" -var="{{host}}_boot_from_disk=true"

  # Switching boot order does not guarantee that PVE reboots an already-running
  # installer. Reboot explicitly only after the ISO has been ejected.
  vmid="$(tofu -chdir={{tofu_dir}} output -raw {{host}}_vm_id)"
  printf 'header = "Authorization: PVEAPIToken=%s"\n' "$PROXMOX_VE_API_TOKEN" |
    curl -fsS --config - -X POST "{{pve_url}}/api2/json/nodes/roshar/qemu/$vmid/status/reboot" |
    jq -r '.data'

  for _ in $(seq 1 60); do
    if ssh -o BatchMode=yes -o ConnectTimeout=5 \
      -o "UserKnownHostsFile=$ssh_hosts" -o StrictHostKeyChecking=accept-new \
      "${plain_ssh_identity_opts[@]}" \
      "root@{{host}}.local.ryk.sh" \
      'test "$(findmnt -n -o FSTYPE /)" = btrfs && { test "{{host}}" = rysn && findmnt -n /home && findmnt -n /persist || systemctl is-active --quiet comin; }' \
      >/dev/null 2>&1; then
      echo "{{host}} booted NixOS from disk"
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
