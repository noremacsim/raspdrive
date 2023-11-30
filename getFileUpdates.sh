#!/bin/bash -eu

source /root/bin/envsetup.sh

if [ -e "$JSON_DB" ]; then

    json_data=$(cat "$JSON_DB")
    current_value=$(jq -r '.files' <<<"$json_data")
    total_count=$(find "$MOUNT_USB_LOC" | wc -l)

    if [ "$current_value" -ne "$total_count" ]; then
        absolute_difference=$((total_count - current_value))
        bash /root/bin/sendPushNotification "New Files Been Added" "$absolute_difference new files" start
        updated_json_data=$(jq --argjson total_count "$total_count" '.files = $total_count' <<<"$json_data")
        echo "$updated_json_data" > "$JSON_DB"
    fi
else
    touch "$JSON_DB"
    echo '{ "files": "0" }' > "$JSON_DB"
fi

exit 0