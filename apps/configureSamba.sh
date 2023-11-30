#!/bin/bash

apt -y --force-yes install samba --fix-missing

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

	[USBData]
	   read only = yes
	   locking = no
	   path = /mnt/usbdata
	   guest ok = yes
	   create mask = 0775
	   veto files = /._*/.DS_Store/
	   delete veto files = yes
	EOF

sudo service smbd restart
