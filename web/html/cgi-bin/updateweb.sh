#!/bin/bash

TARGET_DIR="/var/www/html/"
DOWNLOAD_URL="https://github.com/noremacsim/raspdrive-webui/releases/latest/download/raspdrive-ui.zip"
CURL_ERR_LOG="/tmp/curl.err"

echo "Content-type: text/plain"
echo

# Remove existing directory
rm -Rf "$TARGET_DIR/app"
rm -Rf /tmp/webui.zip

# Download ZIP file
echo "Downloading ZIP file from $DOWNLOAD_URL..."
if ! curl -s -S --stderr "$CURL_ERR_LOG" -L -o /tmp/webui.zip "$DOWNLOAD_URL"; then
    echo "Failed to download ZIP file. Exiting."
    exit 1
fi

# Extract contents to target directory
echo "Extracting contents to $TARGET_DIR..."
unzip -o /tmp/webui.zip -d "$TARGET_DIR"

echo 'Update Complete'