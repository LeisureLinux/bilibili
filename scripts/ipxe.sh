#!/bin/sh
# Setup a web server on IPXE_SERVER
# Download netboot .tar.gz from Alpine, decompress, rename dirname "boot" to arch name
# Create a dir start on the web server and place the ipxe text file there.
#
# Tested working only on: x86_64, aarch64 as of 2023/05/28
#
# Always exit qemu with Ctr-a + x (Use Ctr-a + h for help)
#
# IPXE_SERVER="http://192.168.99.140/start"
IPXE_SERVER="http://192.168.7.11/ipxe/boot"
# IPXE_SERVER="http://192.168.200.200/ipxe/boot"

x86_64() {
	sudo kvm -cpu host -accel kvm \
		-m 4G -smp 2 \
		-boot n \
		-device virtio-net-pci,netdev=vnet,id=net0,mac=52:54:00:11:55:88 \
		-netdev bridge,id=vnet,br=mynetbr99 \
		-monitor telnet:127.0.0.1:1234,server,nowait \
		-display curses -nographic

	# ,ifname=mynet,script=no,downscript=no \
	# -netdev tap,id=vnet,ifname=mynet,script=no,downscript=no \
	#    -netdev '{"type":"tap","fd":"32","id":"hostnet0"}' \
	#    -device '{"driver":"e1000","netdev":"hostnet0","id":"net0","mac":"","bus":"pci.0","addr":"0x3"}'      \
	# -net nic,model=e1000,macaddr=50:58:22:66:55:88 -net bridge \
	# -netdev bridge,id=vnet,br=mynet \

	# -netdev user,id=net0,net=192.168.222.0/24,ip=192.168.222.11,host=192.168.222.22,bootfile=${IPXE_SERVER}/menu.ipxe \
	# -device virtio-net-pci,netdev=net0 \

	# -append "root=/dev/nfs rw nfsroot=192.168.xx.xx:/opt/remote/nfsroot/rpi4b-arm64 ip=dhcp"
	# -echr 2 \
	# QEMU in -nographic mode uses Ctrl+A as its own escape character,
	# echr 2 will switch it to Ctrl+B
}

v_install() {
	# Use F11 to switch full-screen
	# Define Network with:
	#  <bridge name='mynetbr99' stp='on' delay='0'/>
	#   <ip address='192.168.111.1' netmask='255.255.255.0'>
	#     <dhcp>
	#       <range start='192.168.111.100' end='192.168.111.150'/>
	#       <host mac='52:54:00:11:55:88' name='demo-01' ip='192.168.111.88'/>
	#       <bootp file='http://192.168.7.11/ipxe/boot/menu.ipxe'/>
	#     </dhcp>
	#   </ip>
	# virt-xml --edit --network clearxml,bootp=
	# virt-xml debian11-06 --edit --network source="default"
	virt-install --name test \
		--osinfo detect=on,require=off \
		--disk none --memory 2048 \
		--pxe --serial pty \
		--network network=mynet,mac=52:54:00:11:55:88
	virsh destroy test && virsh undefine test
}

ppc64le() {
	local cpu="POWER10"
	local machine="pseries"
	qemu-system-ppc64le -cpu $cpu -M $machine \
		-m 2G -smp 2 \
		-netdev user,id=net0,tftp=/nfsroot/VMs/alpine/tftp,bootfile=/ppc64le.ipxe \
		-device virtio-net-pci,netdev=net0,bootindex=1 \
		-display curses -nographic
	# ,romfile=/usr/lib/ipxe/qemu/compat-256k-efi-virtio.rom \
	# -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
	# ,romfile=/usr/share/qemu-efi-aarch64/1af41000.efirom \
	# console="hvc0"
}

s390x() {
	# local console="ttysclp0"
	local cpu="max"
	local machine="s390-ccw-virtio-7.2"
	# Beside the normal guest firmware (which is loaded from the file s390-ccw.img
	# in the data directory of QEMU, or via the -bios option), QEMU ships with a
	# small TFTP network bootloader firmware for virtio-net-ccw devices, too.
	# This firmware is loaded from a file called s390-netboot.img in the QEMU data directory.
	# In case you want to load it from a different filename instead,
	# you can specify it via the -global s390-ipl.netboot_fw=filename command line option.
	# qemu-system-s390x -netdev user,id=n1,tftp=...,bootfile=... \
	# -device virtio-net-ccw,netdev=n1,bootindex=1
	qemu-system-s390x -cpu $cpu -M $machine \
		-m 2G -smp 2 \
		-bios /usr/share/qemu/s390-ccw.img \
		-netdev user,id=net0,tftp=/nfsroot/VMs/alpine/tftp,bootfile=/s390x.ipxe \
		-device virtio-net-ccw,netdev=net0,bootindex=1 \
		-display curses -nographic
}
#
armv7() {
	local cpu="cortex-a15"
	local machine="virt"
	# todo: rebuild QEMU_EFI.fd file per:
	# https://openrt.gitbook.io/open-surfacert/development/please-read/leander-devnotes/efi-linux-booting/qemu-emulation
	cp /usr/share/AAVMF/AAVMF32_VARS.fd /tmp/arm32.img
	data_dir="/nfsroot/VMs/alpine/arm32/qemu"
	data_dir="/home/axu/Loongson/edk2-platforms"
	qemu-system-arm -cpu $cpu -M $machine \
		-m 2G -smp 2 \
		-bios $data_dir/QEMU_EFI.fd \
		-netdev user,id=net0,ipv6=no,bootfile=${IPXE_SERVER}/armv7.ipxe \
		-device virtio-net-pci,netdev=net0,romfile=/usr/lib/ipxe/qemu/arm32-efi/1af41000.efirom \
		-display curses -nographic
	# -drive if=pflash,format=raw,unit=1,file=/tmp/arm32.img \
	# -drive if=pflash,format=raw,unit=0,readonly=yes,file=/usr/share/AAVMF/AAVMF32_CODE.fd \
	# -drive file=fat:rw:boot/ \
	# -pflash $data_dir/flash0.img \
	# -pflash $data_dir/flash1.img \
	# -pflash /tmp/arm32.img -pflash /usr/share/AAVMF/AAVMF32_CODE.fd \
	# -netdev type=tap,id=net0 -device virtio-net-device,netdev=net0,mac=$randmac

	# 	# qemu-system-arm -display none -machine virt -drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/AAVMF/AAVMF32_CODE.fd
	# -bios /usr/share/AAVMF/AAVMF32_CODE.fd \
	# -netdev user,id=net0,tftp=/nfsroot/VMs/alpine/tftp,bootfile=/armv7.ipxe \
	# -monitor file:/dev/null -serial file:/dev/stdout

	# qemu-system-arm -display none -machine virt -drive \
	# if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/AAVMF/AAVMF32_CODE.fd
	# -monitor file:/dev/null -serial file:/dev/stdout

	#-chardev file,path=armv7_debug.log,id=edk2_debug \
	# -device virtio-debugcon,iobase=0x402,chardev=edk2_debug
	# DXE The first occurance is loading of the DXE IPL (Initial Program Loader),
	# which prints the following log:  DXE IPL Entry
	# BDS The first occurance is loading of the BDS DXE driver,
	# -netdev user,id=net0,bootfile=${IPXE_SERVER}/armv7.ipxe \
	# ,romfile=/usr/share/qemu-efi-aarch64/1af41000.efirom \
	# -boot n \
	# -pflash QEMU_EFI.img \
	# if using -bios option above does't work you can try to extract the img file and use the -pflash option
	#  -pflash QEMU_EFI.img
	#  -drive file=$ISO,id=cdrom,if=none,media=cdrom \
	#  -device virtio-scsi-device -device scsi-cd,drive=cdrom \
	#  -serial vc:80Cx24C
}

aarch64() {
	# How to build the romfile: https://github.com/ipxe/ipxe/issues/130
	# use lspci -nn to find the relevant IDs of your network card
	# 00:03.0 Ethernet controller [0200]: Red Hat, Inc. Virtio network device [1af4:1000]
	qemu-system-aarch64 -cpu cortex-a72 -M virt \
		-m 2G -smp 2 \
		-bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
		-netdev user,id=net0,bootfile=${IPXE_SERVER}/aarch64.ipxe \
		-device virtio-net-pci,netdev=net0,romfile=/usr/share/qemu-efi-aarch64/1af41000.efirom \
		-display curses -nographic
}

# Main Prog.
# [ "$1" != "x86_64" -a "$1" != "aarch64" ] && echo "Syntax: $0 x86_64|aarch64" && exit 0
$1
