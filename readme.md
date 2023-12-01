# What Is RaspDrive

RaspDrive is a project forked from the teslausb and found on reddit where using the raspberrypi gadget we can mount the raspberry pi as a virtual usb

the benefits of this is we can plug out (usb storage) into a computer/car and send events/notifications or automatically upload the usb files to the cloud.

currently the way this works is by monitoring changes on the usb if there is a change and the usb is inactive with will unmount get the changes then remount the usb

### Setup Raspberry Pi Install RaspDrive

- first, flash the image of your choice onto the device of your choice.
  - If using a Raspberry Pi, I recommend using the Raspberry Pi Imager to flash the "Raspberry Pi OS Lite" image: click "Choose OS", then "Raspberry Pi OS (other)", then "Raspberry Pi OS Lite (32-bit)". The 64-bit Lite OS might also work, but is untested. You can preconfigure network settings and user info in the "advanced settings" menu of the Raspberry Pi Imager before flashing. If you do not preconfigure network settings, you will need to connect the Raspberry Pi to a keyboard and monitor to log in and configure it later. 
  - If using another device, using Armbian is recommended.
  - whichever device and flavor of linux you choose, it is recommended to use a non-desktop version of the OS to avoid the additional boot time and storage that a full desktop install requires. Look for "lite", "CLI", "server", "minimal" or similar names.


- boot the device and log in to it. If you did not already configure network settings on the device, you should do so now, since RaspDrive setup needs access to the internet to install. On Armbian, use the nmtui command to easily connect to wifi (choose 'Activate a connection', then select your wifi network). Even if you'll be using ethernet during install, you should configure wifi before proceeding with installing RaspDrive.


Once you're logged in to the device and the device has network access, run the following commands:
```
    sudo -i
    apt update
    apt install curl
    curl https://raw.githubusercontent.com/noremacsim/raspdrive/main/install.sh | bash
```