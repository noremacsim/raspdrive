#!/bin/bash

# Extract folder parameter from QUERY_STRING
IFS='=' read -r -a query_parts <<< "$QUERY_STRING"
folder_path="${query_parts[1]:-}"

echo "Content-type: text/plain"
echo

find "/mnt/usbdata/$folder_path" -maxdepth 1 -mindepth 1 -printf '%y\t%P\n' | sort