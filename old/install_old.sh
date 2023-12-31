#!/bin/bash -eu

source /root/bin/envsetup.sh
source /root/bin/functions.sh

if [ -e "$SETUP_COMPLETE" ]; then
    echo 'Setup has already been completed';
    exit 0;
else
    apt update
    apt upgrade
    apt-get -y --force-yes install python3
    apt -y --force-yes install python3-pip
    apt -y --force-yes install python3-watchdog
    apt-get -y --force-yes install jq

    enableTheUSBDriver
    formatConnectedUSB
    mountConnectedUSB
    createContainerFile
    sh /root/bin/apps/configureApps.sh
    touch "$SETUP_COMPLETE"
    mv /root/bin/rc.local /etc/rc.local
    reboot
fi

