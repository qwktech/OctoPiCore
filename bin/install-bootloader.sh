#!/bin/sh

FCOSEFIPARTITION=$(lsblk $1 -J -oLABEL,PATH  | jq -r '.blockdevices[] | select(.label == "EFI-SYSTEM").path')
mkdir /tmp/FCOSEFIpart
mount ${FCOSEFIPARTITION} /tmp/FCOSEFIpart
rsync -avh --no-perms --no-group --no-owner --ignore-existing ${PWD}/build/boot/efi/ /tmp/FCOSEFIpart/
umount ${FCOSEFIPARTITION}
