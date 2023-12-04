#!/bin/bash -eu

setup_progress "configuring nginx"

# delete existing nginx fstab entries
sed -i "/.*\/nginx tmpfs.*/d" /etc/fstab
# and recreate them
echo "tmpfs /var/log/nginx tmpfs nodev,nosuid 0 0" >> /etc/fstab
echo "tmpfs /var/lib/nginx tmpfs nodev,nosuid 0 0" >> /etc/fstab
# only needed for initial setup, since systemd will create these automatically after that
mkdir -p /var/log/nginx
mkdir -p /var/lib/nginx
mount /var/log/nginx
mount /var/lib/nginx

apt-get -y --force-yes install nginx fcgiwrap libnginx-mod-http-fancyindex fuse libfuse-dev g++ net-tools wireless-tools ethtool

# install data files and config files
systemctl stop nginx.service &> /dev/null || true
mkdir -p /var/www
umount /var/www/html/RaspDrive &> /dev/null || true
rm -rf /var/www/html
cp -r "$SOURCE_DIR/web/html" /var/www/
ln -s /boot/raspdrive-headless-setup.log /var/www/html/
mkdir /var/www/html/RaspDrive
cp -rf "$SOURCE_DIR/web/raspdrive.nginx" /etc/nginx/sites-available
ln -sf /etc/nginx/sites-available/raspdrive.nginx /etc/nginx/sites-enabled/default

# Setup /etc/nginx/.htpasswd if user requested web auth, otherwise disable auth_basic
if [ -n "${WEB_USERNAME:-}" ] && [ -n "${WEB_PASSWORD:-}" ]
then
  apt-get -y --force-yes install apache2-utils
  htpasswd -bc /etc/nginx/.htpasswd "$WEB_USERNAME" "$WEB_PASSWORD"
else
  sed -i 's/auth_basic "Restricted Content"/auth_basic off/' /etc/nginx/sites-available/raspdrive.nginx
fi

# install the fuse layer needed to work around an incompatibility
#g++ -o /root/cttseraser -D_FILE_OFFSET_BITS=64 "$SOURCE_DIR/webcttseraser.cpp" -lstdc++ -lfuse

function curlwrapper () {
  setup_progress "curl $*" > /dev/null
  local attempts=0
  while ! curl -s -S --stderr /tmp/curl.err --fail "$@"
  do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 20 ]
    then
      setup_progress "giving up after 20 tries"
      setup_progress "$(cat /tmp/curl.err)"
      exit 1
    fi
    setup_progress "'curl $*' failed, retrying" > /dev/null
    sntp -S time.google.com || true
    sleep 3
  done
}

# install new UI (compiled js/css files)
curlwrapper -L -o /tmp/webui.zip https://github.com/noremacsim/raspdrive-webui/releases/latest/download/raspdrive-ui.zip
unzip /tmp/webui.zip -d /var/www/html
if [ -d /var/www/html/new ] && ! [ -e /var/www/html/new/favicon.ico ]
then
  ln -s /var/www/html/favicon.ico /var/www/html/new/favicon.ico
fi


#cat > /sbin/mount.ctts << EOF
##!/bin/bash -eu
#/root/cttseraser "\$@" -o allow_other
#EOF
#chmod +x /sbin/mount.ctts

#sed -i '/mount.ctts/d' /etc/fstab
#echo "mount.ctts#/mutable/RaspDrive /var/www/html/RaspDrive fuse defaults,nofail,x-systemd.requires=/mutable 0 0" >> /etc/fstab

sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf

# to get diagnostics and perform other teslausb functionality,
# nginx needs to be able to sudo
echo 'www-data ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/010_www-data-nopasswd
chmod 440 /etc/sudoers.d/010_www-data-nopasswd

# allow multiple concurrent cgi calls
cat > /etc/default/fcgiwrap << EOF
DAEMON_OPTS="-c 4 -f"
EOF

setup_progress "done configuring nginx"