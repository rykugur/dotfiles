#!/usr/bin/env bash

# a simple bootstrap script to setup my env after creating an LXC
# Adapted for Alpine Linux (apk-based) instead of Debian/Ubuntu.
# Updated: Use bash as the user's shell, install eza, and configure starship/aliases for bash.

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
MY_USERNAME="${MY_USERNAME:-dusty}" # Default: "dusty"; override with $MY_USERNAME
MY_FULLNAME="${MY_FULLNAME:-Dusty}" # Optional, for gecos field
MY_PASSWORD="${MY_PASSWORD:-changeme}"

# Check if default is being used and warn
if [[ "$MY_PASSWORD" == "changeme" ]]; then
	warn "Using default password - consider changing it immediately."
fi

# ===================================================================

# Must run as root
if [[ $EUID -ne 0 ]]; then
	error "This script must be run as root"
fi

log "Updating package index..."
apt update || error "Failed to update package list"

add-apt-repository -y ppa:maveonair/helix-editor
apt update

log "Installing OpenSSH server and extra packages..."
apt install -y openssh-server sudo curl wget htop git eza starship helix || error "Failed to install packages"

log "Enabling and starting SSH..."
systemctl enable ssh || error "Failed to enable SSH"
systemctl start ssh || error "Failed to start SSH"

useradd -m -c "$MY_FULLNAME" -s /bin/bash "$MY_USERNAME" || error "Failed to create user"
echo "${MY_USERNAME}:${MY_PASSWORD}" | chpasswd || warn "Failed to set password"
usermod -aG sudo "$MY_USERNAME" || warn "Failed to add user to sudo group"

# Prohibit root SSH login with password
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart ssh || warn "Failed to restart SSH (may already be running)"

log "Installing starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y || warn "Starship install failed (continuing anyway)"

log "Setting some aliases..."
cat >> /root/.bashrc <<EOF
alias dc='docker compose'
alias ls='$LS_CMD -l'
alias ll='$LS_CMD -la'
eval "\$(starship init bash)"
EOF

cat >> "/home/${MY_USERNAME}/.bashrc" <<EOF
alias dc='docker compose'
alias ls='eza -l'
alias ll='eza -la'
eval "\$(starship init bash)"
EOF

log "Bootstrap complete!"
echo
echo "User '$MY_USERNAME' created and added to sudo group"
echo "You can now log in with: ssh $MY_USERNAME@<container-ip>"
