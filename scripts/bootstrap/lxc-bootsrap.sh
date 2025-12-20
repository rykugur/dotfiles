#!/usr/bin/env bash

# a simple bootstrap script to setup my env after creating an LXC
# most LXC's will be created with community scripts, using either
# debian or ubuntu.

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[*] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

# === CONFIGURATION - OVERRIDE WITH ENV VARS ===
MY_USERNAME="${MY_USERNAME:-dusty}"         # Default: "dusty"; override with $MY_USERNAME
MY_FULLNAME="${MY_FULLNAME:-Dusty}"         # Optional, for gecos field
MY_PASSWORD="${MY_PASSWORD:-changeme}"

# Check if default is being used and warn
if [[ "$MY_PASSWORD" == "changeme" ]]; then
  warn "Using default password - consider changing it immediately."
fi

# Additional packages you always want
EXTRA_PACKAGES="sudo curl wget htop git"

# ===================================================================

# Must run as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

log "Updating package index..."
apt update || error "Failed to update package list"

log "Installing OpenSSH server and extra packages..."
apt install -y openssh-server $EXTRA_PACKAGES || error "Failed to install packages"

log "Enabling and starting SSH..."
systemctl enable ssh || error "Failed to enable SSH"
systemctl start ssh || error "Failed to start SSH"

useradd -m -c "$MY_FULLNAME" -s /bin/bash "$MY_USERNAME" || error "Failed to create user"
echo "${MY_USERNAME}:${MY_PASSWORD}" | chpasswd || error "Failed to set password"

# Add user to sudo group
usermod -aG sudo "$MY_USERNAME" || error "Failed to add user to sudo group"

# Configure passwordless sudo
echo "$MY_USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/"$MY_USERNAME"
chmod 0440 /etc/sudoers.d/"$MY_USERNAME"
# Validate sudoers file to avoid lockout
visudo -c || error "Invalid sudoers configuration"

# Prohibit root SSH login with password
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart ssh || warn "Failed to restart SSH (may already be running)"

log "Installing starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y || warn "Starship install failed (continuing anyway)"

log "Installing helix..."
curl -fsSL https://raw.githubusercontent.com/rykugur/dotfiles/refs/heads/master/scripts/bootstrap/install-helix.sh | bash -s -- || warn "Helix install failed (continuing anyway)"

log "Installing eza (or fallback to exa)..."
if apt install -y eza; then
  LS_CMD="eza"
else
  warn "eza not available; falling back to exa"
  apt install -y exa || warn "exa also not available"
  LS_CMD="exa"
fi

log "Setting some aliases..."
cat >> /root/.bashrc <<EOF
alias dc='docker-compose'  # Note: fails on docker > 2.x
alias ls='$LS_CMD -l'
alias ll='$LS_CMD -la'
eval "\$(starship init bash)"
EOF

cat >> "/home/${MY_USERNAME}/.bashrc" <<EOF
alias ls='$LS_CMD -l'
alias ll='$LS_CMD -la'
eval "\$(starship init bash)"
EOF

chown "${MY_USERNAME}:${MY_USERNAME}" "/home/${MY_USERNAME}/.bashrc"

log "Bootstrap complete!"
echo
echo "User '$MY_USERNAME' created and added to sudo group"
echo "Passwordless sudo enabled"
echo "Helix and starship installed"
echo "You can now log in with: ssh $MY_USERNAME@<container-ip>"
