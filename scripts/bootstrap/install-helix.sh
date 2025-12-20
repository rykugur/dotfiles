#!/usr/bin/env bash

# Quick script to install the latest Helix release on Debian/Ubuntu LXC
# Installs the pre-built binary (no .deb needed)

set -euo pipefail  # Better error handling

REPO="helix-editor/helix"
API_URL="https://api.github.com/repos/$REPO/releases/latest"
RELEASE_DATA=$(curl -s "$API_URL")

# Get latest tag (e.g., 25.07)
TAG=$(echo "$RELEASE_DATA" | grep '"tag_name"' | cut -d '"' -f4)

if [ -z "$TAG" ]; then
    echo "Error: Failed to fetch latest release tag"
    exit 1
fi

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH_SUFFIX="x86_64" ;;
    aarch64) ARCH_SUFFIX="aarch64" ;;
    *)       echo "Error: Unsupported architecture $ARCH"; exit 1 ;;
esac

# Asset name pattern (e.g., helix-25.07-x86_64-linux.tar.xz)
ASSET="helix-${TAG}-${ARCH_SUFFIX}-linux.tar.xz"
ASSET_URL="https://github.com/$REPO/releases/download/$TAG/$ASSET"

FILE_NAME=$(basename "$ASSET_URL")

echo "Downloading latest Helix ($TAG) for $ARCH..."
curl -L -o "$FILE_NAME" "$ASSET_URL"

echo "Extracting $FILE_NAME..."
tar -xf "$FILE_NAME"

# The extract creates a directory like helix-25.07-x86_64-linux/
EXTRACT_DIR=$(tar -tf "$FILE_NAME" | head -1 | cut -d/ -f1)

# Install binary and runtime
install -m 755 "$EXTRACT_DIR/hx" /usr/local/bin/hx
cp -r "$EXTRACT_DIR/runtime" /usr/local/share/helix/

# Cleanup
rm -rf "$FILE_NAME" "$EXTRACT_DIR"

echo "Helix $TAG installed successfully!"
echo "Run with: hx"
echo "Runtime directory: /usr/local/share/helix/runtime"
