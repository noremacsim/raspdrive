#!/bin/bash

cat << EOF
HTTP/1.0 200 OK
Content-type: text/plain

EOF
find /mnt/usbdata -printf '%P\n' | sort
