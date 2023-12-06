#!/bin/bash

TARGET_DIR="/var/www/html/app"
DOWNLOAD_URL="https://github.com/noremacsim/raspdrive-webui/releases/latest/download/raspdrive-ui.zip"
CURL_ERR_LOG="/tmp/curl.err"

sudo rm -Rf "$TARGET_DIR"

function curlwrapper() {
  local attempts=0
  while ! curl -s -S --stderr "$CURL_ERR_LOG" --fail "$@"
  do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 20 ]; then
      echo "Exceeded maximum download attempts. Exiting."
      exit 1
    fi
    echo "Retrying download attempt $attempts..."
    sntp -S time.google.com || true
    sleep 3
  done
}

echo "Downloading ZIP file from $DOWNLOAD_URL..."
curlwrapper -L -o /tmp/webui.zip "$DOWNLOAD_URL"

echo "Extracting contents to $TARGET_DIR..."
unzip /tmp/webui.zip -d "$TARGET_DIR"

echo "Script completed successfully."