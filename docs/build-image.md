### Building a raspdrive image


To build a ready to flash one-step setup image, do the following:

1. Clone pi-gen from https://github.com/RPi-Distro/pi-gen
2. Follow the instructions in the pi-gen readme to install the required dependencies
3. In the pi-gen folder, run:
    ```
    echo 'IMG_NAME=raspdrive' > config
    echo 'HOSTNAME=raspdrive' >> config
    echo 'STAGE_LIST="stage0 stage1 stage2 stage_usb"' >> config
    rm -rf stage2/EXPORT_NOOBS stage2/EXPORT_IMAGE
    mkdir stage_usb
    touch stage_usb/EXPORT_IMAGE
    cp stage2/prerun.sh stage_usb/prerun.sh
    ```
4. Copy pi_build/pi-gen-sources/00-raspdrive-tweaks to the pi-gen/stage_usb folder
5. Adjust `DATA_SIZE` in scripts/qcow2_handling to have more free space on the root partition. For the prebuilt image, it was hardcoded to 2 GB by inserting `let DATA_SIZE=2*1024*1024*1024/$BLOCK_SIZE` before the call to `resize2fs -p`.
6. Run `build.sh` or `build-docker.sh`, depending on how you configured pi-gen to build the image
7. Sit back and relax, this could take a while