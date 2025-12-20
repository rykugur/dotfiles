#!/usr/bin/env bash

# Script to create a Debian or Ubuntu LXC container on Proxmox using community scripts with default settings,
# then run a bootstrap script inside the newly created container.

# Usage:
#   ./create_lxc_with_bootstrap.sh [debian|ubuntu]
#
# Example:
#   ./create_lxc_with_bootstrap.sh debian
#   ./create_lxc_with_bootstrap.sh ubuntu
#
# The script will prompt for any required inputs during container creation (uses defaults where possible).
# After creation, it will automatically execute the bootstrap script inside the container.

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

echo "Creating $OS LXC container using community script with default settings..."
echo "Follow the prompts (press Enter for defaults where possible)."

if [[ "$OS" == "debian" ]]; then
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"
elif [[ "$OS" == "ubuntu" ]]; then
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/ubuntu.sh)"
fi

echo "Container creation complete."

# Prompt for the CTID (Container ID) of the newly created container
read -r -p "Enter the CTID of the newly created container: " CTID

# Verify the container exists
if ! pct status "$CTID" &>/dev/null; then
  echo "Error: Container with CTID $CTID not found."
  exit 1
fi

echo "Starting container $CTID if not already running..."
pct start "$CTID" || true

echo "Waiting a few seconds for the container to boot..."
sleep 10

# Note: There appears to be a typo in the original requested URL ("bootsrap" instead of "bootstrap").
# Using the correct URL based on the existing script.

BOOTSTRAP_URL="https://raw.githubusercontent.com/rykugur/dotfiles/master/scripts/bootstrap/lxc-bootstrap-env.sh"

echo "Executing bootstrap script inside container $CTID..."
pct exec "$CTID" -- bash -c "curl -fsSL $BOOTSTRAP_URL | bash"

echo "Bootstrap complete!"
echo "The container is now set up with the user's environment (SSH, sudo user, starship, helix, etc.)."
