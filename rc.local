#!/bin/bash -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

# Print the IP address
_IP=$(hostname -I) || true
if [ "$_IP" ]
then
  printf "My IP address is %s\n" "$_IP"
fi

# Uninstall interactive keyboard setup
if systemctl list-units --all | grep -q "keyboard-setup"; then
    systemctl disable keyboard-setup
    echo "Unit keyboard-setup disabled."
else
    echo "Unit keyboard-setup does not exist."
fi

# uninstall interactive userconfig setup
if systemctl list-units --all | grep -q "userconfig"; then
    systemctl disable userconfig
    echo "Unit userconfig disabled."
else
    echo "Unit userconfig does not exist."
fi

SETUP_LOGFILE=/boot/raspdrive-headless-setup.log

function write_all_leds {
  for led in /sys/class/leds/*
  do
    echo "$1" > "$led/$2" || true
  done
}

function error_strobe() {
  modprobe ledtrig_timer || true
  write_all_leds timer trigger
  while true
  do
    write_all_leds 1 delay_on
    write_all_leds 100 delay_off
    sleep 1
    write_all_leds 0 delay_on
    sleep 1
  done
}

function setup_progress () {
  echo "$( date ) : $1" >> "$SETUP_LOGFILE" || echo "can't write to $SETUP_LOGFILE"
  echo "$1"
}

function get_script () {
  local local_path="$1"
  local name="$2"
  local remote_path="${3:-}"

  IFS=". " read -r start_time _ < /proc/uptime

  while ! curl -o "$local_path/$name" https://raw.githubusercontent.com/noremacsim/raspdrive/main/"$remote_path"/"$name"
  do
    setup_progress "get_script failed, retrying"
    sntp -S time.google.com || true
    sleep 3
    IFS=". " read -r now _ < /proc/uptime
    if [ $((now - start_time)) -gt 60 ]
    then
      setup_progress "failed to get script after 60 seconds, exiting"
      return 1
    fi
  done
  chmod +x "$local_path/$name"
}

function safesource {
  cat <<EOF > /tmp/checksetupconf
#!/bin/bash -eu
source '$1' &> /tmp/checksetupconf.out
EOF
  chmod +x /tmp/checksetupconf
  if ! /tmp/checksetupconf
  then
    setup_progress "Error in $1:"
    setup_progress "$(cat /tmp/checksetupconf.out)"
    error_strobe &
    exit 1
  fi
  source "$1"
}

if [ -e /boot/RASPDRIVE_SETUP_FINISHED ]
then
   echo 'Setup Complete'
else
  if [ -e "/boot/raspdrive_setup_variables.conf" ]
  then
    mv /boot/raspdrive_setup_variables.conf /root/
    dos2unix /root/raspdrive_setup_variables.conf
  fi

  if [ -e "/root/raspdrive_setup_variables.conf" ]
  then
    safesource /root/raspdrive_setup_variables.conf
  elif [ -e "/boot/raspdrive_setup_variables.conf.sample" ]
  then
    setup_progress "no config file found, but sample file is present."
  else
    setup_progress "no config file found."
  fi

  # Good to start setup at this point
  # This begins the Headless Setup loop
  # If the FINISHED file does not exist then we start setup. Otherwise passes on to normal loop
  if [ ! -e "/boot/RASPDRIVE_SETUP_FINISHED" ]
  then
    touch "/boot/RASPDRIVE_SETUP_STARTED"

    # Grab the setup variables. Should still be there since setup isn't finished.
    # This is a double check to cover various scenarios of mixed headless/not headless setup attempts
    if [ -e "/boot/raspdrive_setup_variables.conf" ] && [ ! -e  "/root/raspdrive_setup_variables.conf" ]
    then
      mv /boot/raspdrive_setup_variables.conf /root/
      dos2unix /root/raspdrive_setup_variables.conf
    fi
    if [ -e "/root/raspdrive_setup_variables.conf" ]
    then
      source "/root/raspdrive_setup_variables.conf"
    else
      # No conf file found, can't complete setup
      setup_progress "Setup appears not to have completed, but you didn't provide a raspdrive_setup_variables.conf."
    fi

    # Make the bin dir if needed to grab the setup script into it and persist
    if [ ! -d "/root/bin" ]
    then
      mkdir "/root/bin"
    fi

    if [ ! -e "/root/bin/setup_raspdrive" ]
    then
      REPO=${REPO:-noremacsim}
      BRANCH=${BRANCH:-main}
      # Script doesn't exist, grab it.
      setup_progress "Grabbing main setup file."
      if ! get_script /root/bin setup_raspdrive bin
      then
        setup_progress "Failed to retrieve setup script. Check network settings."
        error_strobe &
        exit 0
      fi
    fi

    setup_progress "Starting setup."

    # Start setup. This should take us all the way through to reboot
    if ! /root/bin/setup_raspdrive
    then
      error_strobe &
      exit 0
    fi

    # reboot for good measure, also restarts the rc.local script
    exec reboot
  fi
fi

# we're done. If setup completed successfully, usb will have been
# started as a systemd service at this point

exit 0
