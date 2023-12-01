#!/bin/bash

function log_progress () {
  if declare -F setup_progress > /dev/null
  then
    setup_progress "configure-samba: $1"
    return
  fi
  echo "configure-samba: $1"
}

SAMBA_GUEST=${SAMBA_GUEST:-false}

if [ "$SAMBA_GUEST" = "true" ]
then
  GUEST_OK="yes"
else
  GUEST_OK="no"
fi

if ! hash smbd &> /dev/null
then
  log_progress "Installing samba and dependencies..."
  # before installing, move some of samba's folders off of the
  # soon-to-be-readonly root partition

  mkdir -p /var/cache/samba
  mkdir -p /var/run/samba

  if ! grep -q samba /etc/fstab
  then
    echo "tmpfs /var/run/samba tmpfs nodev,nosuid 0 0" >> /etc/fstab
    echo "tmpfs /var/cache/samba tmpfs nodev,nosuid 0 0" >> /etc/fstab
  fi

  mount /var/cache/samba
  mount /var/run/samba

  DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install samba
  service smbd start
  echo -e "raspberry\nraspberry\n" | smbpasswd -s -a pi
  service smbd stop
  log_progress "Done."
fi

# remove obsolete fstab entry
sed -i '/^tmpfs \/mnt\/smbexport tmpfs nodev,nosuid 0 0$/d' /etc/fstab

# always update smb.conf in case we're updating a previous install
cat <<- EOF > /etc/samba/smb.conf
	[global]
	   deadtime = 2
	   workgroup = WORKGROUP
	   dns proxy = no
	   log file = /var/log/samba.log.%m
	   max log size = 1000
	   syslog = 0
	   panic action = /usr/share/samba/panic-action %d
	   server role = standalone server
	   passdb backend = tdbsam
	   obey pam restrictions = yes
	   unix password sync = yes
	   passwd program = /usr/bin/passwd %u
	   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
	   pam password change = yes
	   map to guest = bad user
	   min protocol = SMB2
	   usershare allow guests = yes
           unix extensions = no
           wide links = yes

	[RaspDrive]
	   read only = yes
	   locking = no
	   path = /mnt/usbdata
	   guest ok = $GUEST_OK
	   create mask = 0775
	   veto files = /._*/.DS_Store/
	   delete veto files = yes
	EOF
