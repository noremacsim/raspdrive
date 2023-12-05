#!/bin/bash -eu

source /root/bin/envsetup.sh

while [ ! -d "/mnt/connectedUSB" ]; do
    echo 'waiting to mount /mnt/connectedUSB'
    sleep 1
done

while [ ! -d "/mnt/usbdata" ]; do
    echo 'waiting to mount /mnt/usbdata'
    sleep 1
done

/root/bin/enable_gadget.sh || true
python3 /root/bin/usb_service.py
