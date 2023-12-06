#!/bin/bash

sudo rm -Rf /var/www/html/app

function curlwrapper () {
  local attempts=0
  while ! curl -s -S --stderr /tmp/curl.err --fail "$@"
  do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 20 ]
    then
      exit 1
    fi
    sntp -S time.google.com || true
    sleep 3
  done
}

curlwrapper -L -o /tmp/webui.zip https://github.com/noremacsim/raspdrive-webui/releases/latest/download/raspdrive-ui.zip
unzip /tmp/webui.zip -d /var/www/html

sudo reboot &> /dev/null