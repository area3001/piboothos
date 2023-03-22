## Description
This repository contains an [external tree](https://buildroot.org/downloads/manual/manual.html#outside-br-custom) for [Buildroot](https://buildroot.org/). Buildroot is a tool that simplifies and automates the process of building a complete Linux system for an embedded system, using cross-compilation. Our external tree for Buildroot contains configurations and packages to build SD card images for the Raspberry Pi 4 based PiBooth. Buildroot itself is added as a git submodule.

The generated SD card image includes the following:
* U-boot bootloader: bootloader which supports the A/B upgrade mechanism (OTA).
* Kernel, device trees and drivers: to support all the hardware of PiBooth Hat that are mounted on the 40 pin connector of the Raspberry Pi.
* Udev and startup scripts: to initialise and setup all the hardware and processes of the PiBooth OS.
* Dropbear SSH server: to connect to the pibooth from a remote computer
* Rauc: to update the system software OTA

## Prerequisites for building
The prerequisites for building are the same as [the prerequisites of buildroot](https://buildroot.org/downloads/manual/manual.html#requirement-mandatory).

## Building
Clone the repository and update the submodules.
To build:
```
cd buildroot
make BR2_EXTERNAL=../ pibooth_rpi4_defconfig O=output/pibooth_rpi4
make BR2_EXTERNAL=../ O=output/pibooth_rpi4
```
The resulting image will be located in ```output/pibooth_rpi4/images/sdcard.img```.

Optionally, to speed up your build, you can use the Buildroot variable ```BR2_JLEVEL=<number>``` to set the ```J=<number>``` for make. Then wait...

## Installing
Install on a SD card with ```dd```:
```
dd if=output/pibooth_rpi4/images/sdcard.img of=/dev/mmcblk0 bs=1M
```
Plug the SD card into a Raspberry Pi and apply power.

## Boot procedure

At boot the image starts a few processes.

First, the image starts the udev process, which makes sure that the hardware that comes up gets configured and renamed correctly according to the udev rules. For example:
* Network interfaces are set up:
 * ```eth0``` is configured to run a DHCP client
 * ```wlan0``` is configured to use the ```wpa_supplicant.conf``` file located in the first partition (we call it the boot partition because it is mounted on ```/boot``` in the root filesystem) if available, and run a DHCP client
 * On the Raspberry Pi 4, we configure the USB-C connection as a USB ethernet gadget ```usb0```. It runs a DHCP server, so if you connect the Raspberry Pi 4 USB-C port to your laptop, you will get a new ethernet interface which will receive an IP in the range of ```192.199.10.0/24``` from the Raspberry Pi. By default, the Raspberry Pi 4 will have the IP ```192.199.10.1```.

Then, the PiBooth starts up a Dropbear SSH server at port 22. As mentioned before, if you have the Raspberry Pi 4 USB-C plugged in, you will be able to log into the Raspberry Pi using:
```
ssh root@192.199.10.1
```
You can create the following alias in your SSH config (```~/.ssh/config```) to make it easier:
```
Host pibooth
     User root
     HostName 192.199.10.1
     Port 22
```
Then reach it using:
```
ssh pibooth
```

By default, the node name will be its hostname: ```pibooth-<mac address of eth0>```. The OS also starts mDNS/avahi, so you can also find your PiBooth on your network using it hostname and use it to log in using SSH for example:
```
ssh root@pibooth-<mac address of eth0>.local
```

## Upgrading
You can upgrade an existing system using [Rauc](https://rauc.io/). First upload the OTA upgrade file (ending in ```*.raucb``` in ```output/pibooth_rpi4/images/```) to a read-write partition on your Raspberry Pi using ```scp```:
```
scp output/pibooth_rpi4/images/ota-*.raucb root@pibooth:/root/ota.raucb
```

Then login to your device with ssh and upgrade using rauc:
```
rauc install /root/ota.raucb
```
After that, reboot to activate the upgraded system. This upgrade overwrites the content of the boot partition and overwrites the other rootfs partition with the update and then selects it as the new main RootFS at next boot.

## Partition layout and Rootfs

The partition layout on the SD card is as follows:

| MBR |
|-----|
| boot (FAT32, 64MB) |
| u-boot environment (8MB)* |
| Rootfs A (ext4, 1GB)* |
| Rootfs B (ext4, 1GB)* |
| Read-write (ext4, rest of the SD card) |

Partitions marked with ```*``` are extended partitions.

The contents of the boot partition:
* Kernel image
* Device tree and device tree overlays
* uboot bootloader image
* u-boot boot script
* Raspberry Pi boot files (```config.txt```, ```cmdline.txt```, ```start.elf```, ```fixup.dat```)
* Optional: ```wpa_supplicant.conf``` with Wifi SSID information

The next partition contains the u-boot environment. This contains variables that are used by the bootloader and the OTA upgrade system to select the RootFS partition to boot.

Then follows 2 partitions of the same size with the Root filesystem. Be dault they are mounted read-only at boot to improve the wear on the SD card.

The last partition is only created at first boot and takes up all the remaining free space of the SD card. It is mounted read-write at boot. Some parts of the read-only rootfs are bind-mounted onto the read-write partition to make them writeable:
* ```/root```: the home folder of the root user
* ```/etc/dropbear```: to store the SSH keys
* ```/var/lib```: to store the Docker data
* ```/var/log```: to store log files
* ```/var/lock```: to store lock files

## Wifi
To connect using Wifi, provide a ```wpa_supplicant.conf``` file in the ```/boot``` partition (```/dev/mmcblk0p1```) of the SD card and reboot. The device should connect automatically to your wifi.
Here is an example configuration:
```
country=be
update_config=1
ap_scan=1
ctrl_interface=/var/run/wpa_supplicant

network={
  ssid="Your SSID"
  psk="Your password"
}
```