#!/bin/bash -eu

if [ "${BASH_SOURCE[0]}" = "$0" ]
then
  echo "$0 must be sourced, not executed"
  exit 1
fi

function safesource {
  cat <<EOF > /tmp/checksetupconf
#!/bin/bash -eu
source '$1' &> /tmp/checksetupconf.out
EOF
  chmod +x /tmp/checksetupconf
  if ! /tmp/checksetupconf
  then
    if declare -F setup_progress > /dev/null
    then
      setup_progress "Error in $1:"
      setup_progress "$(cat /tmp/checksetupconf.out)"
    else
      echo "Error in $1:"
      cat /tmp/checksetupconf.out
    fi
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$1"
}

function read_setup_variables {
  if [ -z "${setup_file+x}" ]
  then
    local -r setup_file=/root/raspdrive_setup_variables.conf
  fi
  if [ -e $setup_file ]
  then
    # "shellcheck" doesn't realize setup_file is effectively a constant
    # shellcheck disable=SC1090
    safesource $setup_file
  else
    echo "couldn't find $setup_file"
    return 1
  fi

  # TODO: change this "declare" to "local" when github updates
  # to a newer shellcheck.
  declare -A newnamefor

  newnamefor[shareuser]=SHARE_USER
  newnamefor[sharepassword]=SHARE_PASSWORD
  newnamefor[timezone]=TIME_ZONE
  newnamefor[usb_drive]=DATA_DRIVE
  newnamefor[USB_DRIVE]=DATA_DRIVE

  local oldname
  for oldname in "${!newnamefor[@]}"
  do
    local newname=${newnamefor[$oldname]}
    if [[ -z ${!newname+x} ]] && [[ -n ${!oldname+x} ]]
    then
      local value=${!oldname}
      export $newname="$value"
      unset $oldname
    fi
  done

  # set defaults for things not set in the config
  REPO=${REPO:-noremacsim}
  BRANCH=${BRANCH:-main}

  CONFIGURE_ARCHIVING=${CONFIGURE_ARCHIVING:-true}
  UPGRADE_PACKAGES=${UPGRADE_PACKAGES:-false}
  export USB_HOSTNAME=${USB_HOSTNAME:-usb}
  export NOTIFICATION_TITLE=${NOTIFICATION_TITLE:-${USB_HOSTNAME}}
  SAMBA_ENABLED=${SAMBA_ENABLED:-false}
  SAMBA_GUEST=${SAMBA_GUEST:-false}
  INCREASE_ROOT_SIZE=${INCREASE_ROOT_SIZE:-0}
  export DATA_DRIVE=${DATA_DRIVE:-''}
}

read_setup_variables

if [ -t 0 ]
then
  if ! declare -F log > /dev/null
  then
    function log { echo "$@"; }
    export -f log
  fi
  complete -W "diagnose upgrade install" setup_raspdrive
fi

function isRaspberryPi {
  grep -q "Raspberry Pi" /sys/firmware/devicetree/base/model
}

function isPi4 {
  grep -q "Raspberry Pi 4" /sys/firmware/devicetree/base/model
}
export -f isPi4

function isPi2 {
  grep -q "Raspberry Pi Zero 2" /sys/firmware/devicetree/base/model
}
export -f isPi2

function isRockPi4 {
  grep -q "ROCK Pi 4" /sys/firmware/devicetree/base/model
}
export -f isRockPi4

function isRadxaZero {
  grep -q "Radxa Zero" /sys/firmware/devicetree/base/model
}
export -f isRadxaZero

for STATUSLED in \
  /sys/class/leds/led0 \
  /sys/class/leds/ACT \
  /sys/class/leds/user-led2 \
  /sys/class/leds/radxa-zero:green \
  /tmp/fakeled
do
  if [ -d  "$STATUSLED" ]
  then
    break;
  fi
done

if [ ! -d "$STATUSLED" ]
then
  mkdir -p "$STATUSLED"
fi

if [ -f /boot/firmware/cmdline.txt ]
then
  export CMDLINE_PATH=/boot/firmware/cmdline.txt
elif [ -f /boot/cmdline.txt ]
then
  export CMDLINE_PATH=/boot/cmdline.txt
else
  export CMDLINE_PATH=/dev/null
fi

if [ -f /boot/firmware/config.txt ]
then
  export PICONFIG_PATH=/boot/firmware/config.txt
elif [ -f /boot/config.txt ]
then
  export PICONFIG_PATH=/boot/config.txt
else
  export PICONFIG_PATH=/dev/null
fi

