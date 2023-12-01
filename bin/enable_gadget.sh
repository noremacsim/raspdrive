#!/bin/bash -eu

source /root/bin/envsetup.sh

if ! configfs_root=$(findmnt -o TARGET -n configfs)
then
  echo "error: configfs not found"
  exit 1
fi
readonly gadget_root="$configfs_root/usb_gadget/RaspDrive"

# USB supports many languages. 0x409 is US English
readonly lang=0x409

# configuration name can be anything, the convention
# appears to be to use "c"
readonly cfg=c

if [ -d "$gadget_root" ]
then
  echo "already prepared"
  exit 0
fi

modprobe libcomposite

mkdir -p "$gadget_root/configs/$cfg.1"

# common setup
echo 0x1d6b > "$gadget_root/idVendor"  # Linux Foundation
echo 0x0104 > "$gadget_root/idProduct" # Composite Gadget
echo 0x0100 > "$gadget_root/bcdDevice" # v1.0.0
echo 0x0200 > "$gadget_root/bcdUSB"    # USB 2.0
mkdir -p "$gadget_root/strings/$lang"
mkdir -p "$gadget_root/configs/$cfg.1/strings/$lang"
echo "RaspDrive-$(grep Serial /proc/cpuinfo | awk '{print $3}')" > "$gadget_root/strings/$lang/serialnumber"
echo RaspDrive > "$gadget_root/strings/$lang/manufacturer"
echo "RaspDrive Composite Gadget" > "$gadget_root/strings/$lang/product"
echo "RaspDrive Config" > "$gadget_root/configs/$cfg.1/strings/$lang/configuration"

if isPi4
then
  echo 500 > "$gadget_root/configs/$cfg.1/MaxPower"
elif isPi2
then
  echo 200 > "$gadget_root/configs/$cfg.1/MaxPower"
else
  echo 100 > "$gadget_root/configs/$cfg.1/MaxPower"
fi

# mass storage setup
mkdir -p "$gadget_root/functions/mass_storage.0"
echo "/mnt/connectedUSB/usbdata.bin" > "$gadget_root/functions/mass_storage.0/lun.0/file"
echo "RaspDrive $(du -h /mnt/connectedUSB/usbdata.bin | awk '{print $1}')" > "$gadget_root/functions/mass_storage.0/lun.0/inquiry_string"


ln -sf "$gadget_root/functions/mass_storage.0" "$gadget_root/configs/$cfg.1"

# activate
ls /sys/class/udc > "$gadget_root/UDC"

if [ -e "/mnt/usbdata" ]; then
  if mountpoint -q /mnt/usbdata; then
      umount /mnt/usbdata
  fi
  mount /mnt/connectedUSB/usbdata.bin /mnt/usbdata
else
  mkdir /mnt/usbdata
  mount /mnt/connectedUSB/usbdata.bin /mnt/usbdata
fi