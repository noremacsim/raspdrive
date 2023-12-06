#!/bin/bash -eu

if [ "${BASH_SOURCE[0]}" != "$0" ]
then
  echo "${BASH_SOURCE[0]} must be executed, not sourced"
  return 1 # shouldn't use exit when sourced
fi

# Unload the module that was loaded by cmdline.txt
modprobe -r g_ether
/usr/bin/tvservice -o || log "failed to turn off hdmi"

export USB_MOUNT=/mnt/usbdata

source /root/bin/envsetup.sh

if ! grep -q timer "$STATUSLED/trigger"
then
  modprobe ledtrig-timer || log "timer LED trigger unavailable"
fi

if ! grep -q heartbeat "$STATUSLED/trigger"
then
  modprobe ledtrig-heartbeat || log "heartbeat LED trigger unavailable"
fi

export LOG_FILE=/var/log/usb_loop.log

function log () {
  echo -n "$( date ): " >> "$LOG_FILE"
  echo "$@" >> "$LOG_FILE"
}

function wifichecker {
  dmesg -w | {
    while TMOUT=1 read -r line
    do
      true
    done
    wifi=working
    while read -r line
    do
      case $line in
        *"failed to enable fw supplicant")
          if [ "$wifi" = "working" ]
          then
            wifi="notworking"
          else
            log "restarting wifi because of: $line"
            modprobe -r brcmfmac cfg80211 brcmutil || true
            modprobe brcmfmac || true
            while TMOUT=1 read -r line
            do
              true
            done
            wifi="working"
          fi
          ;;
        *)
          wifi=working
          ;;
      esac
    done
  }
}

function connect_usb_drives_to_host() {
  log "Connecting usb to host..."
  /root/bin/enable_gadget.sh
  log "Connected usb to host."
  sleep 5
}

function disconnect_usb_drives_from_host () {
  log "Disconnecting usb from host..."
  if /root/bin/disable_gadget.sh
  then
    echo 'gadget disabled'
  fi
  log "Disconnected usb from host."
}

function check_if_usb_gadget_is_mounted () {
  LUNFILE=/sys/kernel/config/usb_gadget/raspdrive/configs/c.1/mass_storage.0/lun.0/file
  if [ -n "$(cat /sys/kernel/config/usb_gadget/raspdrive/UDC)" ] &&
     [ -e "$LUNFILE" ] &&
     [ "$(cat $LUNFILE)" = /mnt/backingfiles/usbdata.bin ]
  then
    return
  fi

  log "USB Gadget not mounted. Fixing files and remounting..."
  disconnect_usb_drives_from_host
  connect_usb_drives_to_host
}

function set_time () {
  log "Trying to set time..."
  local -r uptime_start=$(awk '{print $1}' /proc/uptime)
  local -r clocktime_start=$(date +%s.%N)
  for _ in {1..5}
  do
    if sntp -S time.google.com
    then
      local -r uptime_end=$(awk '{print $1}' /proc/uptime)
      local -r clocktime_end=$(date +%s.%N)
      log "$(awk "BEGIN {printf \"Time adjusted by %f seconds after %f seconds\", $clocktime_end-$clocktime_start, $uptime_end-$uptime_start}")"
      return
    fi
    log "sntp failed, retrying..."
    sleep 2
  done
  log "Failed to set time"
}

wifichecker
connect_usb_drives_to_host
check_if_usb_gadget_is_mounted
python3 /root/bin/usb_service.py