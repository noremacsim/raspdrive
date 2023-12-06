#!/bin/bash

sudo rm -Rf /var/www/html/app

curlwrapper -L -o /tmp/webui.zip https://github.com/noremacsim/raspdrive-webui/releases/latest/download/raspdrive-ui.zip
unzip /tmp/webui.zip -d /var/www/html

sudo reboot &> /dev/null