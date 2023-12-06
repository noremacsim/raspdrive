#!/bin/bash

# Function to convert dBm to percentage
dbm_to_percentage() {
    local value=$1
    local max_value=-100
    local min_value=0

    # Ensure the value is within the valid range
    value=$(echo "$value" | awk '{print int($1)}')
    value=$((value > 0 ? 0 : (value < max_value ? max_value : value)))

    # Calculate the percentage based on the given range
    local percentage=$((100 - (value - min_value) * 100 / (max_value - min_value)))
    echo "$percentage"
}

# Run iw scan and filter SSID and signal strength
wifi_info=$(sudo iw dev wlan0 scan | grep "SSID\|signal")

# Extract SSID and signal strength
ssid=()
signal_strength=()

while read -r line; do
    if [[ $line == *"SSID"* ]]; then
        ssid_candidate=$(echo "$line" | awk '{print $2}')
        if [[ "$ssid_candidate" != "\x00\x00\x00\x00\x00\x00\x00\x00\x00" ]]; then
            ssid+=("$ssid_candidate")
        fi
    elif [[ $line == *"signal"* ]]; then
        signal_dbm=$(echo "$line" | awk '{print $2}')
        signal_percentage=$(dbm_to_percentage "$signal_dbm")
        signal_strength+=("$signal_percentage")
    fi
done <<< "$wifi_info"

# Create JSON format
json_output='['

for ((i = 0; i < ${#ssid[@]}; i++)); do
    json_output+='{"ssid": "'"${ssid[i]}"'", "signal": "'"${signal_strength[i]}"'"},'
done

# Remove trailing comma
json_output=${json_output%,}]

echo "Content-type: text/plain"
echo

# Print the JSON output
echo "$json_output"
