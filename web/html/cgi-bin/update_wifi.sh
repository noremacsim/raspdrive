#!/bin/bash

# Function to decode URL-encoded values
urldecode() {
    echo -e "$(sed 's/+/ /g; s/%\(..\)/\\x\1/g')"
}

# Initialize variables
ssid=""
password=""

# Parse query string using grep and awk
query_string="$QUERY_STRING"
ssid=$(echo "$query_string" | grep -oP 'ssid=\K[^&]*' | urldecode)
password=$(echo "$query_string" | grep -oP 'password=\K.*' | urldecode)

# Generate wpa_supplicant.conf
sudo tee /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=GB

network={
  ssid="$ssid"
  psk="$password"
  key_mgmt=WPA-PSK
  id_str="AP1"
}

EOF

# Respond with HTTP 200 OK and JSON content type
cat << EOF
HTTP/1.0 200 OK
Content-type: application/json

{
  "message": "Configuration updated successfully"
}
EOF

