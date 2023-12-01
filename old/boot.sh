#!/bin/bash -eu

source /root/bin/envsetup.sh
source /root/bin/functions.sh

mountConnectedUSB
/bin/bash /root/bin/mountUSB.sh
python3 /root/bin/usbService.py