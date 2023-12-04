#!/bin/bash -eu

source /root/bin/envsetup.sh

# Get the size of $DATA_DRIVE in bytes using blockdev
usb_size_bytes=$(blockdev --getsize64 "$DATA_DRIVE")

# Subtract 4 gigabytes from the total size
usb_size_bytes=$((usb_size_bytes - 4 * 1024 * 1024 * 1024))

# Convert bytes to gigabytes
usb_size_gigabytes=$(awk "BEGIN {print ${usb_size_bytes}/1024/1024/1024}")

# Allocate space for the file using fallocate
fallocate -l "${usb_size_gigabytes}G" /mnt/connectedUSB/usbdata.bin

# Format the file with FAT32
mkdosfs /mnt/connectedUSB/usbdata.bin -F 32 -I
