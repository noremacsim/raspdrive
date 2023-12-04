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
umount /var/www/html/app &> /dev/null || true
rm -rf /var/www/html
cp -r "$SOURCE_DIR/web/html" /var/www/
ln -s /boot/raspdrive-headless-setup.log /var/www/html/
mkdir /var/www/html/app
cp -rf "$SOURCE_DIR/web/raspdrive.nginx" /etc/nginx/sites-available
ln -sf /etc/nginx/sites-available/raspdrive.nginx /etc/nginx/sites-enabled/default

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

# install app UI (compiled js/css files)
curlwrapper -L -o /tmp/webui.zip https://github.com/noremacsim/raspdrive-webui/releases/latest/download/raspdrive-ui.zip
unzip /tmp/webui.zip -d /var/www/html
if [ -d /var/www/html/app ] && ! [ -e /var/www/html/app/favicon.ico ]
then
  ln -s /var/www/html/favicon.ico /var/www/html/app/favicon.ico
fi


sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf

echo 'www-data ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/010_www-data-nopasswd
chmod 440 /etc/sudoers.d/010_www-data-nopasswd

# allow multiple concurrent cgi calls
cat > /etc/default/fcgiwrap << EOF
DAEMON_OPTS="-c 4 -f"
EOF

chmod -R 755 /var/www/html/cgi-bin/
chown -R www-data:www-data /var/www/html/cgi-bin/

setup_progress "done configuring nginx"