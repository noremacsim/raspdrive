#!/bin/bash

IFS='=' read -r -a query_parts <<< "$QUERY_STRING"
ssid="${query_parts[1]:-}"
password="${query_parts[2]:-}"

sudo bash -c "cat > /etc/wpa_supplicant/wpa_supplicant.conf <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=GB

network={
  ssid='$ssid'
  psk='$password'
  key_mgmt=WPA-PSK
  # Uncomment the following line, if you are trying
  # to connect to a network with a _hidden_ SSID
  #scan_ssid=1
  id_str='AP1'
}
EOF"

cat << EOF
HTTP/1.0 200 OK
Content-type: application/json

EOF