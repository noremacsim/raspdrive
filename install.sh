#!/bin/bash -eu
#
# Pre-install script to make things look sufficiently like what
# the main Raspberry Pi centric install scripts expect.
#

function error_exit {
  echo "STOP: $*"
  exit 1
}

function flash_rapidly {
  for led in /sys/class/leds/*
  do
    if [ -e "$led/trigger" ]
    then
      if ! grep -q timer "$led/trigger"
      then
        modprobe ledtrig-timer || echo "timer LED trigger unavailable"
      fi
      echo timer > "$led/trigger" || true
      if [ -e "$led/delay_off" ]
      then
        echo 150 > "$led/delay_off" || true
        echo 50 > "$led/delay_on" || true
      fi
    fi
  done
}

## Copy setup to rc.local to ensure to continue install after reboot
cat <<- EOF > /etc/rc.local
#!/bin/bash
{
  while ! curl -s https://raw.githubusercontent.com/noremacsim/raspdrive/main/setup/install.sh
  do
    sleep 1
  done
} | bash
EOF
chmod a+x /etc/rc.local

# Copy the sample config file from github
if [ ! -e /boot/raspdrive_setup_variables.conf ] && [ ! -e /root/raspdrive_setup_variables.conf ]
then
  while ! curl -o /boot/raspdrive_setup_variables.conf https://raw.githubusercontent.com/noremacsim/raspdrive/main/conf/raspdrive_setup_variables.conf.sample
  do
    sleep 1
  done
fi

rm -f /etc/rc.local
while ! curl -o /etc/rc.local https://raw.githubusercontent.com/noremacsim/raspdrive/main/rc.local
do
  sleep 1
done
chmod a+x /etc/rc.local

if [ ! -x "$(command -v dos2unix)" ]
then
  apt install -y dos2unix
fi

if [ ! -x "$(command -v sntp)" ]
then
  apt install -y sntp
fi

flash_rapidly
/etc/rc.local