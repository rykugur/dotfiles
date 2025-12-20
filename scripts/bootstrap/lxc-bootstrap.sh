#!/usr/bin/env bash

# Updated script (v2): Create Debian or Ubuntu LXC on Proxmox using community scripts,
# auto-detect the new CTID, then run the bootstrap script inside.

# Usage via curl:
#   curl -fsSL https://raw.githubusercontent.com/grok-archive/temp/main/create_lxc_with_bootstrap_v2.sh | bash -s -- debian
#   curl -fsSL https://raw.githubusercontent.com/grok-archive/temp/main/create_lxc_with_bootstrap_v2.sh | bash -s -- ubuntu

set -euo pipefail

OS="${1:-}"

if [[ -z "$OS" ]]; then
  echo "Error: Please specify 'debian' or 'ubuntu' as the first argument."
  echo "Usage: $0 [debian|ubuntu]"
  exit 1
fi

if [[ "$OS" != "debian" && "$OS" != "ubuntu" ]]; then
  echo "Error: Invalid OS specified. Use 'debian' or 'ubuntu'."
  exit 1
fi

echo "Listing existing containers before creation..."
BEFORE=$(pct list | awk 'NR>1 {print $1}' | sort)

echo "Creating $OS LXC container using community script..."
echo "You will see interactive prompts (CTID, password, etc.). Press Enter for defaults where possible."

if [[ "$OS" == "debian" ]]; then
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"
elif [[ "$OS" == "ubuntu" ]]; then
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/ubuntu.sh)"
fi

echo "Container creation complete."

echo "Listing containers after creation to detect the new one..."
AFTER=$(pct list | awk 'NR>1 {print $1}' | sort)

NEW_CTID=$(comm -13 <(echo "$BEFORE") <(echo "$AFTER") | tr -d ' ')

if [[ -z "$NEW_CTID" || $(echo "$NEW_CTID" | wc -l) -ne 1 ]]; then
  echo "Error: Could not automatically detect the new CTID."
  echo "Existing before: $BEFORE"
  echo "Existing after: $AFTER"
  read -p "Please enter the CTID manually: " NEW_CTID
fi

if [[ -z "$NEW_CTID" ]]; then
  echo "Error: No CTID provided."
  exit 1
fi

echo "Detected/Using CTID: $NEW_CTID"

# Verify the container exists
if ! pct status "$NEW_CTID" &>/dev/null; then
  echo "Error: Container with CTID $NEW_CTID not found or invalid."
  exit 1
fi

echo "Starting container $NEW_CTID if not already running..."
pct start "$NEW_CTID" || true

echo "Waiting 15 seconds for the container to fully boot and network to come up..."
sleep 15

# Corrected bootstrap URL (the original had a typo: bootsrap → bootstrap)
BOOTSTRAP_URL="https://raw.githubusercontent.com/rykugur/dotfiles/master/scripts/bootstrap/lxc-bootstrap-env.sh"

echo "Executing bootstrap script inside container $NEW_CTID..."
pct exec "$NEW_CTID" -- bash -c "curl -fsSL $BOOTSTRAP_URL | bash"

echo "All done!"
echo "Your new $OS container (CTID: $NEW_CTID) is ready."
echo "To enter: pct enter $NEW_CTID"
echo "Then: su - dusty (default password: changeme — change it immediately!)"
