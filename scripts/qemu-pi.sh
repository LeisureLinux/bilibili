#!/bin/sh
# 两种虚拟机类型，Native+Virt
# Virt 类型都可以直接通过 virt-manager 图形界面生成虚拟机
# 三种 OS:
#   1. RaspberryOS on Native, 通过指定 Kernel + dtb 方式启动
#   2. Alpine Linux on Virt with Diskless, 通过指定 netboot 的 kernel + initramfs ，从远程恢复备份信息，安装软件包
#   3. 任意 OS on Virt，可以从任意支持的 OS 启动，只要用 virt-get-kernel 命令抽取出 img 内的 kernel + initrd 即可
# If need debug, can add it as:
# "-D /var/tmp/qemu-$NAME.log -d in_asm,int,mmu"
#
TTY="ttyAMA0"

add_tap() {
	# If want to have "Bridge" Network in guest, run this function first
	# Modify BR value with host Bridge name
	BR="mpbr99"
	TAP=$(echo tap-$1 | cut -c1-15)
	sudo tunctl -t $TAP -u $(whoami)
	sudo brctl addif $BR $TAP
	sudo ifconfig $TAP up
}

# To use Userspace Net, e.g. no need to use "sudo", replace "tap" netdev with "user"
# e.g: -netdev user,id=net0,hostfwd=tcp::2022-:22 -device usb- net,netdev=net0
native() {
	M="raspi3b"
	NAME="softpi3b-native"
	# IMG downloaded from the official site
	# e.g. https://www.raspberrypi.com/software/operating-systems/
	# NJU Mirror: https://mirrors.nju.edu.cn/raspberry-pi-os-images/
	IMG="img/2022-04-04-raspios-bullseye-arm64-lite.img"
	# KERNEL and DTB both extraced from $IMG using guestfish, then mount /dev/sda1 as /boot
	# then run: $tgz-out /boot host-dir/boot-files.tar.gz
	# exit guestfish, extract boot-files.tar.gz
	KERNEL="boot/kernel8.img"
	DTB="boot/bcm2710-rpi-3-b.dtb"
	add_tap $NAME
	sudo qemu-system-aarch64 -no-reboot -nographic -serial mon:stdio \
		-M $M -m 1G -smp 4 \
		--name $NAME -pidfile /run/$NAME.pid \
		-usb -device usb-mouse -device usb-kbd \
		-device usb-net,netdev=tap0 \
		-netdev tap,id=tap0,ifname=$TAP,script=no,downscript=no \
		-kernel $KERNEL -dtb $DTB \
		-drive file=$IMG,format=raw \
		-append "rw earlyprintk loglevel=8 console=$TTY dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2 rootdelay=1"
	# Add init=/bin/sh, then run passwd pi to change pi password
	# Delete tap
	sudo tunctl -d $TAP
}

diskless() {
	NAME="softpi4-diskless"
	# Kernel & Initrd both downloaded from OS Repo. netboot directory
	# NJU mirror: http://mirrors.nju.edu.cn/alpine/edge/releases/$arch/netboot/$KERNEL
	#    + http://mirrors.nju.edu.cn/alpine/edge/releases/$arch/netboot/$INITRD
	KERNEL="boot/vmlinuz-lts"
	INITRD="boot/initramfs-lts"
	# FLASH="/usr/share/AAVMF/AAVMF_CODE.fd"
	# -drive file=$FLASH,if=pflash,format=raw,unit=1,readonly=on \
	CPU="cortex-a72"
	add_tap $NAME
	sudo qemu-system-aarch64 -no-reboot -nographic -serial mon:stdio \
		-M virt -cpu $CPU -m 4G -smp 4 \
		--name $NAME -pidfile /run/$NAME.pid \
		-kernel $KERNEL -initrd $INITRD \
		-device virtio-net-device,netdev=net0 \
		-netdev tap,id=net0,ifname=$TAP,script=no,downscript=no \
		--append "console=$TTY ip=dhcp alpine_repo=http://mirrors.nju.edu.cn/alpine/edge/main/ apkovl=http://192.168.7.11/client.apkovl.tar.gz"
	# 如果需要图形界面，append: modloop=http://mirrors.nju.edu.cn/alpine/edge/releases/$arch/netboot/modloop-lts
	sudo tunctl -d $TAP
}

virt() {
	NAME="softpi4-01"
	# Download disk image from https://raspi.debian.net/tested-images/
	DISK="img/raspi_4_bullseye.img"
	# kernel and initrd images are extracted with virt-get-kernel command from DISK image
	KERNEL="boot/vmlinuz-5.10.0-14-arm64"
	INITRD="boot/initrd.img-5.10.0-14-arm64"
	# FLASH="/usr/share/AAVMF/AAVMF_CODE.fd"
	# -drive file=$FLASH,if=pflash,format=raw,unit=1,readonly=on \
	CPU="cortex-a72"
	add_tap $NAME
	sudo qemu-system-aarch64 -no-reboot -nographic \
		-M virt -cpu $CPU -m 4G -smp 4 \
		--name $NAME -pidfile /run/$NAME.pid \
		-kernel $KERNEL -initrd $INITRD \
		-device virtio-net-device,netdev=net0 \
		-netdev tap,id=net0,ifname=$TAP,vhost=on,script=no,downscript=no \
		-device virtio-blk,drive=hd0,bootindex=0 \
		-drive file=$DISK,format=raw,if=none,id=hd0,cache=writeback \
		-append "console=$TTY root=/dev/vda2 noresume rw"
	sudo tunctl -d $TAP
}

# Main Prog.
[ "$1" != "virt" -a "$1" != "add_tap" -a "$1" != "native" -a "$1" != "diskless" ] && echo "Syntax: $0 virt|native|diskless" && exit 1
$1
