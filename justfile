set shell := ["bash", "-euo", "pipefail", "-c"]

pve_token := "$HOME/.config/pve/agent.token"
pve_url := "https://roshar.local.ryk.sh:8006"

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

# What each comin host is running right now.
comin-status +hosts:
  #!/usr/bin/env bash
  set -euo pipefail
  for h in {{hosts}}; do
    echo "== $h"
    ssh "$h.local.ryk.sh" 'systemctl is-active comin; comin status --oneline || true; readlink /run/current-system'
  done
