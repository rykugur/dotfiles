#!/bin/bash

# just a quickie script to grab the latest helix release and install it
# written primarily for a debian LXC

REPO="helix-editor/helix"
API_URL="https://api.github.com/repos/$REPO/releases/latest"
RELEASE_DATA=$(curl -s "$API_URL")

if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch release data from GitHub API"
    exit 1
fi

# Extract the download URL for the .deb asset
DEB_URL=$(echo "$RELEASE_DATA" | grep -o 'https://github.com[^"]*\.deb' | head -n 1)

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
    sudo dpkg -i $FILE_NAME
    rm $FILE_NAME
else
    echo "Error: Failed to download $FILE_NAME"
    exit 1
    rm $FILE_NAME
fi
