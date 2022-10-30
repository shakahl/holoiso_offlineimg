#!/bin/zsh
## HoloISO rootfs generator

# Start by allocating a RAW disk file
truncate -c -s 20G rootfs.img

# Mount it
sudo losetup -f -P rootfs.img

# TEST
sudo lsblk