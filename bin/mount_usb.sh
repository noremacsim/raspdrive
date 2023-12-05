#!/bin/bash -eu

source /root/bin/envsetup.sh

/root/bin/disable_gadget.sh || true
/root/bin/enable_gadget.sh || true
python3 /root/bin/usb_service.py
