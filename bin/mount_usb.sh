#!/bin/bash -eu

source /root/bin/envsetup.sh

mount /mnt/connectedUSB/usbdata.bin /mnt/usbdata || true
mount /dev/sda /mnt/connectedUSB || true

while [ ! -d "/mnt/connectedUSB" ]; do
    echo 'waiting to mount /mnt/connectedUSB'
    mount /dev/sda /mnt/connectedUSB
    sleep 1
done

while [ ! -d "/mnt/usbdata" ]; do
    echo 'waiting to mount /mnt/usbdata'
    mount /mnt/connectedUSB/usbdata.bin /mnt/usbdata
    sleep 1
done

/root/bin/disable_gadget.sh || true
/root/bin/enable_gadget.sh || true
python3 /root/bin/usb_service.py
