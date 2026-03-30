#!/usr/bin/env bash
set -euo pipefail

REPO="helix-editor/helix"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"

echo "Fetching latest Helix release info..."
RELEASE_JSON=$(curl -fsSL "$API_URL")

DEB_URL=$(echo "$RELEASE_JSON" | grep -o '"browser_download_url": *"[^"]*\.deb"' | head -1 | cut -d'"' -f4)

if [[ -z "$DEB_URL" ]]; then
    echo "Error: No .deb asset found in the latest release." >&2
    exit 1
fi

VERSION=$(echo "$RELEASE_JSON" | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
DEB_FILE="/tmp/helix-${VERSION}.deb"

echo "Downloading Helix ${VERSION}..."
echo "  ${DEB_URL}"
curl -fSL -o "$DEB_FILE" "$DEB_URL"

echo "Installing ${DEB_FILE}..."
sudo dpkg -i "$DEB_FILE"

echo "Cleaning up..."
rm -f "$DEB_FILE"

echo "Done. Installed:"
hx --version
