#!/bin/bash -eu

function log_progress () {
  if declare -F setup_progress > /dev/null
  then
    setup_progress "create-backingfiles: $1"
    return
  fi
  echo "create-backingfiles: $1"
}

log_progress "starting"

# strip trailing slash that shell autocomplete might have added
BACKINGFILES_MOUNTPOINT="${1/%\//}"
USE_EXFAT=false

# Get the size of $DATA_DRIVE in bytes using blockdev
USB_SIZE_BYTES=$(blockdev --getsize64 "$DATA_DRIVE")
USB_SIZE_BYTES=$((USB_SIZE_BYTES - 4 * 1024 * 1024 * 1024))
USB_SIZE_GIGABYTES=$(awk "BEGIN {print ${USB_SIZE_BYTES}/1024/1024/1024}")

log_progress "usbsize: $USB_SIZE_GIGABYTES Gig, mountpoint: $BACKINGFILES_MOUNTPOINT, exfat: $USE_EXFAT"

function first_partition_offset () {
  local filename="$1"
  local size_in_bytes
  local size_in_sectors
  local sector_size
  local partition_start_sector

  size_in_bytes=$(sfdisk -l -o Size -q --bytes "$1" | tail -1)
  size_in_sectors=$(sfdisk -l -o Sectors -q "$1" | tail -1)
  sector_size=$(( size_in_bytes / size_in_sectors ))
  partition_start_sector=$(sfdisk -l -o Start -q "$1" | tail -1)

  echo $(( partition_start_sector * sector_size ))
}

# Note that this uses powers-of-two rather than the powers-of-ten that are
# generally used to market storage.
function dehumanize () {
  echo $(($(echo "$1" | sed 's/GB/G/;s/MB/M/;s/KB/K/;s/G/*1024M/;s/M/*1024K/;s/K/*1024/')))
}

available_space () {
  freespace=$(df --output=avail --block-size=1K "$BACKINGFILES_MOUNTPOINT/" | tail -n 1)
  # leave 10 GB of free space for filesystem bookkeeping and snapshotting
  # (in kilobytes so 10M KB)
  padding=$(dehumanize "10M")
  echo $((freespace-padding))
}

function add_drive () {
  local name="$1"
  local label="$2"
  local size="$3"
  local filename="$4"
  local useexfat="$5"

  log_progress "Allocating ${size}G for $filename..."
  fallocate -l "$size"G "$filename"
  if [ "$useexfat" = true  ]
  then
    echo "type=7" | sfdisk "$filename" > /dev/null
  else
    echo "type=c" | sfdisk "$filename" > /dev/null
  fi

  local partition_offset
  partition_offset=$(first_partition_offset "$filename")

  loopdev=$(losetup -o "$partition_offset" -f --show "$filename")
  log_progress "Creating filesystem with label '$label'"
  if [ "$useexfat" = true  ]
  then
    mkfs.exfat "$loopdev" -L "$label"
  else
    mkfs.vfat "$loopdev" -F 32 -n "$label"
  fi
  losetup -d "$loopdev"

  local mountpoint=/mnt/"$name"

  if [ ! -e "$mountpoint" ]
  then
    mkdir "$mountpoint"
  fi
}

function check_for_exfat_support () {
  # First check for built-in ExFAT support
  # If that fails, check for an ExFAT module
  # in this last case exfat doesn't appear
  # in /proc/filesystems if the module is not loaded.
  if grep -q exfat /proc/filesystems &> /dev/null
  then
    return 0;
  elif modprobe -n exfat &> /dev/null
  then
    return 0;
  else 
    return 1;  
  fi
}

USB_DISK_FILE_NAME="$BACKINGFILES_MOUNTPOINT/usbdata.bin"

# delete existing files, because fallocate doesn't shrink files, and
# because they interfere with the percentage-of-free-space calculation
if [ -e "$USB_DISK_FILE_NAME" ]
then
  if [ -t 0 ]
  then
    read -r -p 'Delete snapshots and recreate usb drives? (yes/cancel)' answer
    case ${answer:0:1} in
      y|Y )
      ;;
      * )
        log_progress "aborting"
        exit
      ;;
    esac
  fi
fi

#TODO: maybe kill any process interfering with the mnt
#killall archiveloop || true
/root/bin/disable_gadget.sh || true
umount -d /mnt/usbdata || true
rm -f "$USB_DISK_FILE_NAME"

# Check if kernel supports ExFAT 
if ! check_for_exfat_support
then
  if [ "$USE_EXFAT" = true ]
  then
    log_progress "kernel does not support ExFAT FS. Reverting to FAT32."
    USE_EXFAT=false
  fi
else
  # install exfatprogs if needed
  if ! hash mkfs.exfat &> /dev/null
  then
    if ! apt install -y exfatprogs
    then
      log_progress "kernel supports ExFAT, but exfatprogs package does not exist."
      if [ "$USE_EXFAT" = true ]
      then
        log_progress "Reverting to FAT32"
        USE_EXFAT=false
      fi
    fi
  fi
fi

# some distros don't include mkfs.vfat
if ! hash mkfs.vfat
then
  apt-get -y --force-yes install dosfstools
fi

add_drive "usbdata" "USBDATA" "$USB_SIZE_GIGABYTES" "$USB_DISK_FILE_NAME" "$USE_EXFAT"
log_progress "created usb backing file"

log_progress "done"
