#!/bin/bash -eu

function check_variable () {
  local var_name="$1"
  if [ -z "${!var_name+x}" ]
  then
    setup_progress "STOP: Define the variable $var_name like this: export $var_name=value"
    exit 1
  fi
}

function check_supported_hardware () {
  if ! grep -q  'Raspberry Pi' /sys/firmware/devicetree/base/model
  then
    return
  fi
  if grep -q 'Raspberry Pi Zero W' /sys/firmware/devicetree/base/model
  then
    return
  fi
  if grep -q 'Raspberry Pi Zero 2' /sys/firmware/devicetree/base/model
  then
    return
  fi
  if grep -q 'Raspberry Pi 4' /sys/firmware/devicetree/base/model
  then
    return
  fi
  setup_progress "STOP: unsupported hardware: '$(cat /sys/firmware/devicetree/base/model)'"
  setup_progress "(only Pi Zero W and Pi 4 have the necessary hardware to run RaspDrive)"
  exit 1
}

function check_udc () {
  local udc
  udc=$(find /sys/class/udc -type l -prune | wc -l)
  if [ "$udc" = "0" ]
  then
    setup_progress "STOP: this device ($(cat /sys/firmware/devicetree/base/model)) does not have a UDC driver"
    exit 1
  fi
}

function check_xfs () {
  setup_progress "Checking XFS support"
  # install XFS tools if needed
  if ! hash mkfs.xfs
  then
    apt-get -y --force-yes install xfsprogs
  fi
  truncate -s 1GB /tmp/xfs.img
  mkfs.xfs -m reflink=1 -f /tmp/xfs.img > /dev/null
  mkdir -p /tmp/xfsmnt
  if ! mount /tmp/xfs.img /tmp/xfsmnt
  then
    setup_progress "STOP: xfs does not support required features"
    exit 1
  fi

  umount /tmp/xfsmnt
  rm -rf /tmp/xfs.img /tmp/xfsmnt
  setup_progress "XFS supported"
}

function check_available_space () {
    if [ -z "$DATA_DRIVE" ]
    then
      setup_progress "DATA_DRIVE is not set. SD card will be used."
    else
      if [ -e "$DATA_DRIVE" ]
      then
        setup_progress "DATA_DRIVE is set to $DATA_DRIVE. This will be used for the virtual usb."
      else
        setup_progress "STOP: DATA_DRIVE is set to $DATA_DRIVE, which does not exist."
        exit 1
      fi
    fi
}


function check_setup_raspdrive () {
  if [ ! -e /root/bin/setup_raspdrive ]
  then
    setup_progress "STOP: setup_raspdrive is not in /root/bin"
    exit 1
  fi

  local parent
  parent="$(ps -o comm= $PPID)"
  if [ "$parent" != "setup_raspdrive" ]
  then
    setup_progress "STOP: $0 must be called from setup_raspdrive: $parent"
    exit 1
  fi
}

check_supported_hardware

check_udc

check_xfs

check_setup_raspdrive

check_available_space
