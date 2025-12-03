#!/usr/bin/env bash

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[*] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

# === CONFIGURATION - OVERRIDE WITH ENV VARS ===
MY_USERNAME="${MY_USERNAME:-dusty}"         # Default: "user"; override with $MY_USERNAME
MY_FULLNAME="${MY_FULLNAME:-Dusty}"         # Optional, for gecos field
DEFAULT_PASSWORD_HASH_CHANGEME="$6$WOlycVNE7cD.zOCu$FC3ztNhdvyNae.bPni6zDcOM/3ZmpwMVQIim1us5stdK6TIv5rrklAn3yp95DJvcSEM95adjhNmAl8IrmHBXA."
# Use a hashed password (mkpasswd -m sha-512)
MY_PASSWORD="${MY_PASSWORD:-$DEFAULT_PASSWORD_HASH_CHANGEME}"

# Check if default is being used and warn
if [[ "$MY_PASSWORD" == "$DEFAULT_PASSWORD_HASH_CHANGEME" ]]; then
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
apt update

log "Installing SSH and extra packages..."
apt install -y openssh-server $EXTRA_PACKAGES

log "Enabling and starting SSH..."
systemctl enable ssh
systemctl start ssh

log "Creating user $MY_USERNAME with pre-defined password or password hash..."
useradd -m -c "$MY_FULLNAME" -s /bin/bash "$MY_USERNAME"
echo "$MY_USERNAME:$MY_PASSWORD" | chpasswd

# Add user to sudo group (works on Debian/Ubuntu)
usermod -aG sudo "$MY_USERNAME"

# Configure passwordless sudo (optional but common)
echo "$MY_USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$MY_USERNAME
chmod 0440 /etc/sudoers.d/$MY_USERNAME

# Optional: Prohibit root SSH login with password (keeps password auth enabled for your user)
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
# Note: PasswordAuthentication remains "yes" (default) since no keys are set up here
systemctl restart ssh

log "Installing helix..."
curl -fsSL https://raw.githubusercontent.com/rykugur/dotfiles/refs/heads/master/scripts/get-helix-debian.sh | bash -s --

log "Bootstrap complete!"
echo
echo "User '$MY_USERNAME' created and added to sudo group"
echo "Passwordless sudo enabled"
echo "Helix was installed"
echo "You can now log in with: ssh $MY_USERNAME@<container-ip>"
