source /root/bin/envsetup.sh

function unmountUSB {
  modprobe -r g_mass_storage
}

function reboot {
    exec reboot
}

function enableTheUSBDriver {

  if grep -q "dtoverlay=dwc2" "/boot/config.txt"; then
      echo "The line 'dtoverlay=dwc2' is already present in /boot/config.txt."
  else
      # Append the line to the end of the file
      echo "dtoverlay=dwc2" | tee -a "/boot/config.txt" > /dev/null
      echo "Added 'dtoverlay=dwc2' to /boot/config.txt."
  fi

  if grep -q "dwc2" "/etc/modules"; then
      echo "The line 'dwc2' is already present in /etc/modules."
  else
      # Append the line to the end of the file
      echo "dwc2" | tee -a "/etc/modules" > /dev/null
      echo "Added 'dwc2' to /etc/modules."
  fi
}

function formatConnectedUSB {
  wipefs -afq "/dev/sda";
  mkfs.ext4 -L connected /dev/sda
}

function mountConnectedUSB {
  if [ -e "$connectedUSB_loc" ]; then
    if mountpoint -q $connectedUSB_loc; then
        umount -l $connectedUSB_loc
    fi
    mount /dev/sda $connectedUSB_loc
  else
    mkdir $connectedUSB_loc
    mount /dev/sda $connectedUSB_loc
  fi

  sh /root/bin/mountUSB.sh
}

function createContainerFile {
  usb_size=$(parted -s /dev/sda unit MB print | awk '$1 ~ /[0-9]/ {print $3}')
  dd bs=1M if=/dev/zero of=/mnt/connectedUSB/usbdata.bin count="1024" status=progress
  mkdosfs /mnt/connectedUSB/usbdata.bin -F 32 -I
}