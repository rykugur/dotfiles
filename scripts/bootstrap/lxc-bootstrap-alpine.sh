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
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

# === CONFIGURATION - OVERRIDE WITH ENV VARS ===
MY_USERNAME="${MY_USERNAME:-dusty}"         # Default: "dusty"; override with $MY_USERNAME
MY_FULLNAME="${MY_FULLNAME:-Dusty}"         # Optional, for gecos field
MY_PASSWORD="${MY_PASSWORD:-changeme}"
PASSWORDLESS_SUDO="${PASSWORDLESS_SUDO:-false}"

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
apk update || error "Failed to update package list"

log "Installing base packages (including bash, openssh, sudo, etc.)..."
apk add --no-cache bash openssh sudo curl wget htop git eza || error "Failed to install packages"

log "Enabling and starting SSH..."
rc-update add sshd default || error "Failed to enable SSH"
rc-service sshd start || error "Failed to start SSH"

log "Creating user '$MY_USERNAME' with bash as shell..."
adduser -D -g "$MY_FULLNAME" -s /bin/bash "$MY_USERNAME" || error "Failed to create user"

# Set password
echo "${MY_USERNAME}:${MY_PASSWORD}" | chpasswd || error "Failed to set password"

# Add user to wheel group for sudo access
addgroup "$MY_USERNAME" wheel || error "Failed to add user to wheel group"

# Configure passwordless sudo if requested
if [[ $PASSWORDLESS_SUDO = "true" ]]; then
  sed -i '/^# %wheel ALL=(ALL) ALL/a %wheel ALL=(ALL) NOPASSWD: ALL' /etc/sudoers
  visudo -c || error "Invalid sudoers configuration"
fi

# Prohibit root SSH login with password
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
rc-service sshd restart || warn "Failed to restart SSH"

log "Installing starship prompt..."
curl -sS https://starship.rs/install.sh | sh -s -- -y || warn "Starship install failed (continuing anyway)"

log "Installing helix editor..."
curl -fsSL https://raw.githubusercontent.com/rykugur/dotfiles/master/scripts/bootstrap/install-helix.sh | bash || warn "Helix install failed (continuing anyway)"

log "Configuring aliases and starship for the new user..."
# Append to user's ~/.bashrc
su - "$MY_USERNAME" -c "cat > ~/.bashrc << 'EOF'
# Custom aliases
alias ls='eza --color=always --icons=always'
alias ll='eza -l --color=always --icons=always'
alias la='eza -la --color=always --icons=always'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
alias dc='docker compose'

# Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval \"\$(starship init bash)\"
fi
EOF"

log "Also adding basic aliases to root's profile (for consistency)..."
cat >> /root/.profile << 'EOF'

# Basic aliases for root (ash shell)
alias ls='eza --color=always --icons=always || ls --color=auto'
alias ll='eza -l --color=always --icons=always || ls -l --color=auto'
alias la='eza -la --color=always --icons=always || ls -la --color=auto'
EOF

log "Bootstrap complete!"
log "User '$MY_USERNAME' created with /bin/bash shell."
log "Starship and aliases configured in ~/.bashrc."
log "Login as the user to see the full setup. Change the default password ASAP!"
