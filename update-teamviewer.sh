#!/bin/bash

# Check if jq (JSON parser) is installed
if ! command -v jq &> /dev/null; then
    echo "jq is required but not installed. Please install jq (sudo apt install jq) and try again."
    exit 1
fi

# Get the currently installed TeamViewer version
INSTALLED_VERSION=$(teamviewer --version 2>/dev/null | awk '/TeamViewer/ {print $(NF-1)}')
if [ -z "$INSTALLED_VERSION" ]; then
    echo "Failed to determine the installed TeamViewer version. Ensure TeamViewer is installed and in your PATH."
    exit 1
fi
echo "Installed TeamViewer version: $INSTALLED_VERSION"

# Get the download page URL for the TeamViewer package
DOWNLOAD_PAGE="https://download.teamviewer.com/download/linux/teamviewer_amd64.deb"

# Follow the redirect to get the actual file URL
REDIRECT_URL=$(curl -sI "$DOWNLOAD_PAGE" | grep -i 'Location' | awk '{print $2}' | tr -d '\r')

# Extract the version from the redirected URL
LATEST_VERSION=$(echo "$REDIRECT_URL" | grep -oP 'teamviewer_[0-9.]+(?=_amd64)' | cut -d'_' -f2)

if [ -z "$LATEST_VERSION" ]; then
    echo "Failed to fetch the latest version. Please check your network and try again."
    exit 1
fi
echo "Latest TeamViewer version: $LATEST_VERSION"

# Compare versions
if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
    echo "You already have the latest version installed."
    exit 0
fi

echo "A new version is available. Updating..."

# Download the latest .deb package
TEMP_DEB=$(mktemp --suffix=.deb)
curl -Lo "$TEMP_DEB" "$REDIRECT_URL"

if [ $? -ne 0 ]; then
    echo "Failed to download the latest TeamViewer package. Please try again."
    rm -f "$TEMP_DEB"
    exit 1
fi

# Install the downloaded package
sudo dpkg -i "$TEMP_DEB"
if [ $? -ne 0 ]; then
    echo "Failed to install the TeamViewer package. You might need to fix dependency issues with 'sudo apt --fix-broken install'."
    rm -f "$TEMP_DEB"
    exit 1
fi

echo "TeamViewer has been updated to version $LATEST_VERSION."
rm -f "$TEMP_DEB"
