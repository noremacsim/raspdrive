#!/bin/bash
# shellcheck disable=SC2016
# SC2016 shellcheck wants double quotes for the free/used space calculation
# below, but that requires additional ugly escaping

if [[ -e /sys/kernel/config/usb_gadget/raspdrive ]]
then
  drives_active=yes
else
  drives_active=no
fi

wifidev=$(find /sys/class/net/ -type l -name 'wl*' -printf '%P' -quit)

if [ -n "$wifidev" ]
then
  wifi_ssid=$(iwgetid -r "$wifidev" || true)
  wifi_freq=$(iwgetid -r -f "$wifidev" || true)
  wifi_strength=$(iwconfig "$wifidev" | grep "Link Quality" | sed 's/ *Link Quality=\([0-9]*\)\/\([0-9]*\)\(.*\)/\1\/\2/')
  read -r _ wifi_ip _ < <(ifconfig "$wifidev" | grep "inet ")
else
  wifi_ssid=
  wifi_freq=
  wifi_strength=
  wifi_ip=
fi

ethdev=$(find /sys/class/net/ -type l \( -name 'eth*' -o -name 'en*' \) -printf '%P' -quit)

if [ -n "$ethdev" ]
then
  read -r _ ether_ip _ < <(ifconfig "$ethdev" | grep "inet ")
  IFS=" :" read -r _ ether_speed < <(ethtool "$ethdev" | grep Speed)
else
  ether_ip=
  ether_speed=
fi

total_available_space=$(stat --format="%s" "/mnt/backingfiles/usbdata.bin")
total_used_space=$(du -sb "/mnt/usbdata" | awk '{print $1}')
total_free_space=$((total_available_space - total_used_space))

read -r -d ' ' ut < /proc/uptime

cat << EOF
HTTP/1.0 200 OK
Content-type: application/json

{
   "cpu_temp": "$(cat /sys/class/thermal/thermal_zone0/temp)",
   "total_space": "$total_available_space",
   "used_space": "$total_used_space",
   "free_space": "$total_free_space",
   "uptime": "$ut",
   "drives_active": "$drives_active",
   "wifi_ssid": "$wifi_ssid",
   "wifi_freq": "$wifi_freq",
   "wifi_strength": "$wifi_strength",
   "wifi_ip": "$wifi_ip",
   "ether_ip": "$ether_ip",
   "ether_speed": "$ether_speed"
}
EOF
