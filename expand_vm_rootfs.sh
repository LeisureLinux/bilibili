#!/bin/sh
# Increase root fs /dev/sda1 on guest domain with 2GB
# Bilibili ID: LeisureLinux
# If the rootfs partition number changed, you have to run grub-install
# First run virt-rescue -d domain-name -i
# Then in the rescue mode, input chroot /sysroot
# Finally run grub-install /dev/sda, and quit with two Ctr-D
size="2G"
dom=$1
[ -z "$dom" ] && echo "Syntax: $0 dom_name" && exit 0
PART=$(sudo virt-filesystems --no-title --long --parts --blkdevs -d $dom | awk '$NF != "-" {print $0}' | sort -n -k3 | tail -1 | awk '{print $1}')
[ -z "$PART" ] && echo "Error: Failed found root part for $dom" && exit 1
echo "Expand Part: $PART"
img=$(sudo virsh -q domblklist $dom | grep -v "iso$" | awk '{print $NF}')
[ -z "$img" ] && echo "Error: no image file found for $dom" && exit 2
sudo qemu-img resize $img +${size}
sudo cp $img $img.orig
# sudo qemu-img create -f qcow2 -o preallocation=metadata $img 7G
sudo virt-resize --no-extra-partition --expand $PART $img.orig $img
sudo rm $img.orig
