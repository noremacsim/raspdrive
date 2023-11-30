#!/bin/bash -eu

source /root/bin/envsetup.sh

echo "Detecting whether to update wpa_supplicant.conf"
if [[ -n "$SSID" ]] && [[ -n "$WIFIPASS" ]]
then
  if [ ! -e /boot/WIFI_ENABLED ]
  then
    if [ -e /root/bin/remountfs_rw ]
    then
      /root/bin/remountfs_rw
    fi
#    setup_progress "Wifi variables specified, and no /boot/WIFI_ENABLED. Building wpa_supplicant.conf."
    cp /root/bin/wpa_supplicant.conf.sample /boot/wpa_supplicant.conf
    sed -i -e "sTEMPSSID${SSID}g" /boot/wpa_supplicant.conf
    sed -i -e "sTEMPPASS${WIFIPASS}g" /boot/wpa_supplicant.conf
    cp /boot/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf

    # set the host name now if possible, so it's effective immediately after the reboot
    local old_host_name
    old_host_name=$(cat /etc/hostname)
    if [[ -n "$USB_HOSTNAME" ]] && [[ "$USB_HOSTNAME" != "$old_host_name" ]]
    then
      local new_host_name="$USB_HOSTNAME"
      sed -i -e "s/$old_host_name/$new_host_name/g" /etc/hosts
      sed -i -e "s/$old_host_name/$new_host_name/g" /etc/hostname
    fi

    dpkg-reconfigure -f noninteractive openssh-server
    rfkill unblock wifi &> /dev/null || true
    for i in /var/lib/systemd/rfkill/*:wlan ; do
      echo 0 > "$i"
    done
    systemctl enable ssh

    touch /boot/WIFI_ENABLED
#    setup_progress "Rebooting..."
    exec reboot
  fi
else
#  setup_progress "skipping wifi setup because variables not specified"
fi