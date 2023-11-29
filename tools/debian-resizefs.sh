#!/bin/bash
#
# Resize root filesystem during boot.
#
# VERSION       :1.0.1
# DATE          :2018-04-01
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# ALTERNATIVE   :http://www.ivarch.com/blogs/oss/2007/01/resize-a-live-root-fs-a-howto.shtml

# Check current filesystem type
ROOT_FS_TYPE="$(sed -n -e 's|^/dev/\S\+ / \(ext4\) .*$|\1|p' /proc/mounts)"
test "$ROOT_FS_TYPE" == ext4 || exit 100

# Copy e2fsck and resize2fs to initrd
cat > /etc/initramfs-tools/hooks/resize2fs <<"EOF"
#!/bin/sh

PREREQ=""

prereqs() {
    echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

. /usr/share/initramfs-tools/hook-functions
copy_exec /sbin/findfs /sbin/findfs-full
copy_exec /sbin/e2fsck /sbin
copy_exec /sbin/resize2fs /sbin
EOF

chmod +x /etc/initramfs-tools/hooks/resize2fs

# Execute resize2fs before mounting root filesystem
cat > /etc/initramfs-tools/scripts/init-premount/resize <<EOF
#!/bin/sh

PREREQ=""

# New size of root filesystem
ROOT_SIZE=${1:-"8G"}

EOF
cat >> /etc/initramfs-tools/scripts/init-premount/resize <<"EOF"
prereqs() {
    echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

# Convert root from possible UUID to device name
echo "root=${ROOT}  "
ROOT_DEVICE="$(/sbin/findfs-full "$ROOT")"
echo "root device name is ${ROOT_DEVICE}  "
# Make sure LVM volumes are activated
if [ -x /sbin/vgchange ]; then
    /sbin/vgchange -a y || echo "vgchange: $?  "
fi
# Check root filesystem
if /sbin/e2fsck -y -v -f "$ROOT_DEVICE"; then
  # Resize
  # debug-flag 8 means debug moving the inode table
  # -f means ignore various checks, which is needed for devices with a bad clock.
  # This should be safe, because e2fsck just completed successfully.
  /sbin/resize2fs -f -d 8 "$ROOT_DEVICE" "$ROOT_SIZE" || echo "resize2fs: $?  "
else
  echo "e2fsck $ROOT_DEVICE failed"
fi
EOF

chmod +x /etc/initramfs-tools/scripts/init-premount/resize

# Regenerate initrd
update-initramfs -v -u

# Remove files
rm -f /etc/initramfs-tools/hooks/resize2fs /etc/initramfs-tools/scripts/init-premount/resize

reboot

# List files in initrd
# lsinitramfs /boot/initrd.img-*-amd64

# Remove files from initrd after reboot
# update-initramfs -u
