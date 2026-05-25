#!/usr/bin/env bash
# Bootstrap a Debian LXC container for the 'dusty' user.
# Tested against Debian 13 (trixie).

set -euo pipefail

USERNAME="dusty"

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root." >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "==> Updating apt..."
apt-get update

echo "==> Installing prerequisites (sudo, curl, ca-certificates, eza)..."
apt-get install -y sudo curl ca-certificates eza

echo "==> Creating user '${USERNAME}'..."
if ! id -u "$USERNAME" >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash "$USERNAME"
fi

# No password — login is via console / SSH keys / passwordless sudo.
passwd --delete "$USERNAME" >/dev/null

echo "==> Configuring passwordless sudo..."
SUDOERS_FILE="/etc/sudoers.d/${USERNAME}"
printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$USERNAME" > "$SUDOERS_FILE"
chmod 0440 "$SUDOERS_FILE"
visudo -c -f "$SUDOERS_FILE" >/dev/null

USER_HOME=$(getent passwd "$USERNAME" | cut -d: -f6)
BASHRC="${USER_HOME}/.bashrc"

echo "==> Installing starship..."
if ! command -v starship >/dev/null 2>&1; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes >/dev/null
fi

echo "==> Updating ${BASHRC}..."
touch "$BASHRC"

add_line() {
    local line="$1"
    grep -qxF "$line" "$BASHRC" || printf '%s\n' "$line" >> "$BASHRC"
}

add_line ''
add_line '# --- bootstrap: dusty ---'
# shellcheck disable=SC2016  # intentional: written verbatim into .bashrc
add_line 'eval "$(starship init bash)"'
add_line "alias ls='eza'"
add_line "alias ll='eza -l'"

chown "${USERNAME}:${USERNAME}" "$BASHRC"

echo "==> Done. User '${USERNAME}' ready (no password, passwordless sudo)."
