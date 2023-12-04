#!/bin/bash -eu

source /root/bin/envsetup.sh

usb_size=$(parted -s $DATA_DRIVE unit MB print | awk '$1 ~ /[0-9]/ {print $3}')
dd bs=1M if=/dev/zero of=/mnt/connectedUSB/usbdata.bin count="$usb_size" status=progress
#fallocate -l "${usb_size}" /mnt/connectedUSB/usbdata.bin
mkdosfs /mnt/connectedUSB/usbdata.bin -F 32 -I