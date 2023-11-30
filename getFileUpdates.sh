#!/bin/bash -eu

json_db="/root/bin/data.json"

if [ -e "$json_db" ]; then

    json_data=$(cat "$json_db")
    current_value=$(jq -r '.files' <<<"$json_data")
    total_count=$(find "/mnt/usbdata" | wc -l)

    if [ "$current_value" -ne "$total_count" ]; then
        absolute_difference=$((total_count - current_value))
        bash /root/bin/sendPushNotification "New Files Been Added" "$absolute_difference new files" start
        updated_json_data=$(jq --argjson total_count "$total_count" '.files = $total_count' <<<"$json_data")
        echo "$updated_json_data" > "$json_db"
    fi
else
    touch "$json_db"
    echo '{ "files": "0" }' > "$json_db"
fi

exit 0