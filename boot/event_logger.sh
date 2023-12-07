#!/bin/bash

WATCH_DIR="/mnt/usbdata"
LOG_FILE="/var/log/file_changes_a.log"
EXISTING_STATE="/var/log/file_changes_b.log"
EVENTS_LOG="/var/log/events.log"
skip_count=0

while true; do

    # Create the log file if it doesn't exist
    touch "$LOG_FILE"
    touch "$EXISTING_STATE"

    # Store the existing state
    find "$WATCH_DIR" -type f ! -path "$LOG_FILE" -exec stat --format="%Y %n" {} + 2>/dev/null | sort > "$EXISTING_STATE"

    # Check if the log file is present in the existing state
    if grep -q "$LOG_FILE" "$EXISTING_STATE"; then
        sed -i "\%$LOG_FILE%d" "$EXISTING_STATE"
    fi

    diff_output=$(diff -u "$EXISTING_STATE" "$LOG_FILE")


    if [ -n "$diff_output" ]; then

        while IFS= read -r line; do

            if [ "$skip_count" -lt 3 ]; then
                ((skip_count++))
                continue
            fi

            echo 'reading line'
            timestamp=$(echo "$line" | awk '{print $1}')
            file_path=$(echo "$line" | cut -d ' ' -f2-)

            echo "$line"
            echo "Time: $timestamp, File: $file_path"

            # Check if the file exists in both states
            if grep -Fq "$file_path" "$LOG_FILE" && grep -Fq "$file_path" "$EXISTING_STATE"; then
                echo 'file exists in both states'
                # Compare the timestamps
                existing_timestamp=$(grep "$file_path" "$EXISTING_STATE" | awk '{print $1}')

                if [ "$timestamp" != "$existing_timestamp" ]; then
                    echo "File Modified: $file_path" >> "$EVENTS_LOG"
                fi
            elif grep -Fq "$file_path" "$LOG_FILE"; then
                echo "File Deleted: $file_path" >> "$EVENTS_LOG"
            elif grep -Fq "$file_path" "$EXISTING_STATE"; then
                echo "New File Added: $file_path" >> "$EVENTS_LOG"
            fi
        done <<< "$diff_output"
    fi

    # Update the log file with the current state
    mv "$EXISTING_STATE" "$LOG_FILE"

    # Adjust the interval as needed
    sleep 1
done
