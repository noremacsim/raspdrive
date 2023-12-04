#!/bin/bash -eu

source /root/bin/envsetup.sh

wipefs -afq "$DATA_DRIVE";
mkfs.ext4 -L raspdrive $DATA_DRIVE