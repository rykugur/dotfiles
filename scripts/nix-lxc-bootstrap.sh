#!/usr/bin/env bash

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[*] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
error() {
	echo -e "${RED}[✗] $1${NC}"
	exit 1
}

# === CONFIGURATION - OVERRIDE WITH ENV VARS ===
_HOSTNAME="${HOSTNAME:-nixy}"
nextid=$(pvesh get /cluster/nextid)
_CTID="${CTID:-$nextid}"
_SWAP="${SWAP:-1024}"
_MEMORY="${MEMORY:-2048}"
TEMPLATE="local:vztmpl/nixos-image-lxc-proxmox-25.05pre-git-x86_64-linux.tar.xz"
STORAGE="local-lvm"

# ===================================================================

# Must run as root
if [[ $EUID -ne 0 ]]; then
	error "This script must be run as root"
fi

log "Bootstrapping nixOS LXC..."
log "  HOSTNAME=${_HOSTNAME}"
log "  CTID=${_CTID}"
log "  MEMORY=${_MEMORY}"
log "  SWAP=${_SWAP}"

log "Creating LXC..."
log "Running pre-start commands..."
log "  Increasing rootfs..."
pct resize "$_CTID" +2G

log "Starting the CT..."
pct start "$_CTID"
echo "Container started."

# Wait for boot and network (robust retry)
log "Waiting for container to boot and become responsive..."
for i in {1..30}; do
  if pct exec "$_CTID" -- true 2>/dev/null; then
    echo "Container is responsive."
    break
  fi
  sleep 5
done

log "  Deleting root password..."
pct exec "$CT_ID" -- bash -c 'source /etc/set-environment && passwd --delete root'
log "  Executing nixos-rebuild..."
# TODO: pick one vvv
# pct exec "$CT_ID" -- nixos-rebuild switch --flake "github:rykugur/dotfiles#${_HOSTNAME}"
# pct exec "$CT_ID" -- bash -c "
#   git clone https://github.com/rykugur/dotfiles.git /tmp/dotfiles &&
#   cd /tmp/dotfiles &&
#   nixos-rebuild switch --flake .#${CT_NAME}
# "
