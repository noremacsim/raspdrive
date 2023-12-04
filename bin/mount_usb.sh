#!/bin/bash -eu

source /root/bin/envsetup.sh

if [ -e "/mnt/connectedUSB" ]; then
  if mountpoint -q /mnt/connectedUSB; then
      umount -f /mnt/connectedUSB
  fi
  mount $DATA_DRIVE /mnt/connectedUSB
else
  mkdir /mnt/connectedUSB
  mount $DATA_DRIVE /mnt/connectedUSB
fi

if [ -e "/mnt/usbdata" ]; then
  if mountpoint -q /mnt/usbdata; then
      umount -f /mnt/usbdata
  fi
  mount /mnt/connectedUSB/usbdata.bin /mnt/usbdata
else
  mkdir /mnt/usbdata
  mount /mnt/connectedUSB/usbdata.bin /mnt/usbdata
fi

/root/bin/disable_gadget.sh || true
/root/bin/enable_gadget.sh || true
python3 /root/bin/usb_service.py
