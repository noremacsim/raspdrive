#!/bin/bash -eu

if [ "${BASH_SOURCE[0]}" != "$0" ]
then
  echo "${BASH_SOURCE[0]} must be executed, not sourced"
  return 1 # shouldn't use exit when sourced
fi

function log_progress () {
  if declare -F setup_progress > /dev/null
  then
    setup_progress "configure-automount: $1"
    return
  fi
  echo "configure-automount: $1"
}

apt-get -y --force-yes install autofs
# the Raspbian Stretch autofs package does not include the /etc/auto.master.d folder
if [ ! -d /etc/auto.master.d ]
then
  mkdir /etc/auto.master.d
fi

echo "/mnt  /etc/auto.raspdrive --timeout=60" | tee -a /etc/auto.master
echo "/mnt  /etc/auto.raspdrive --timeout=60" | tee -a /etc/auto.master.d/autofs

echo "connectedUSB -fstype=exfat :/dev/sda" | sudo tee /etc/auto.raspdrive
echo "usbdata -fstype=vfat :/mnt/connectedUSB/usbdata.bin" | sudo tee -a /etc/auto.raspdrive