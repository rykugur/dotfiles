#!/usr/bin/env bash

# === CONFIGURATION - OVERRIDE WITH ENV VARS ===
MY_USERNAME="${MY_USERNAME:-dusty}"         # Default: "user"; override with $MY_USERNAME
MY_FULLNAME="${MY_FULLNAME:-Dusty}"         # Optional, for gecos field
MY_PASSWORD=''                             # Hashed password (mkpasswd -m sha-512); leave empty for interactive prompt

HELIX_REPO="helix-editor/helix"
HELIX_API_URL="https://api.github.com/repos/$REPO/releases/latest"
HELIX_RELEASE_DATA=$(curl -s "$API_URL")

# Additional packages you always want
EXTRA_PACKAGES="sudo curl wget htop git"

# ===================================================================

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[*] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

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

# Generate hashed password if not provided
if [[ -z "$MY_PASSWORD" ]]; then
    log "No password hash provided - you'll be prompted to set password for $MY_USERNAME"
    adduser --gecos "$MY_FULLNAME" --disabled-password "$MY_USERNAME"
    passwd "$MY_USERNAME"
else
    log "Creating user $MY_USERNAME with pre-defined password hash..."
    useradd -m -c "$MY_FULLNAME" -s /bin/bash "$MY_USERNAME"
    echo "$MY_USERNAME:$MY_PASSWORD" | chpasswd -e
fi

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

# Extract the download URL for the .deb asset
DEB_URL=$(echo "$HELIX_RELEASE_DATA" | grep -o 'https://github.com[^"]*\.deb' | head -n 1)

# Check if a .deb asset was found
if [ -z "$DEB_URL" ]; then
    echo "Error: No .deb asset found in the latest release"
    exit 1
fi

# Extract the file name from the URL
FILE_NAME=$(basename "$DEB_URL")

# Download the .deb file
echo "Downloading $FILE_NAME..."
curl -L -o "$FILE_NAME" "$DEB_URL"

# Check if download was successful
if [ $? -eq 0 ]; then
    echo "Successfully downloaded $FILE_NAME"
    dpkg -i $FILE_NAME
    rm $FILE_NAME
else
    echo "Error: Failed to download $FILE_NAME"
    exit 1
    rm $FILE_NAME
fi

log "Bootstrap complete!"
echo
echo "User '$MY_USERNAME' created and added to sudo group"
echo "Passwordless sudo enabled"
echo "Helix was installed"
echo "You can now log in with: ssh $MY_USERNAME@<container-ip>"
