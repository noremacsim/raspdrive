#!/bin/bash -eu

sync
echo 3 > /proc/sys/vm/drop_caches
sh -c 'echo 3 >/proc/sys/vm/drop_caches'
sync