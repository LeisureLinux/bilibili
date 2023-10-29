#!/bin/sh
# Define a netboot Alpine VM to run adhole, the adblocker
# arch in: x86_64, aarch64, s390x, ppc64le, armv7, armhf
#
#
arch=$1
#
# default values
vm_arch=$arch
os_arch=$arch
domain_type="qemu"
cpu_count=4
mem_size=2048
ker_ver="lts"
# BOOTP="http://boot.netboot.xyz/ipxe/netboot.xyz.lkrn"
boot_dir="http://192.168.99.140/start"

add_kernel() {
	virt-xml $my_domain --edit --boot kernel="$my_dir/vmlinuz-$ker_ver"
	[ $? != 0 ] && echo "Error: found error in kernel define" && virsh undefine $my_domain && exit 1
	virt-xml $my_domain --edit --boot initrd="$my_dir/initramfs-$ker_ver"
	[ $? != 0 ] && echo "Error: found error in initrd define" && virsh undefine $my_domain && exit 2
	virt-xml $my_domain --edit --boot cmdline="$cmdline"
	[ $? != 0 ] && echo "Error: found error in cmdline define" && virsh undefine $my_domain && exit 3
}

aarch64() {
	local fla="rpi"
	local url="http://192.168.99.140/aarch64"
	local apkovl="http://192.168.7.11/apkovl/minimum.tar.gz"
	local modloop="${url}/modloop-${fla}"
	local cmdline="console=ttyS0 ip=dhcp modules=loop,squashfs modloop=${modloop} apkovl=${apkovl}"
	local bootp="http://192.168.99.144/boot.ipxe"
	local iso="http://mirror.nju.edu.cn/alpine/latest-stable/releases/aarch64/alpine-virt-3.18.0-aarch64.iso"

	virt-install --arch aarch64 --name pxe-cmd \
		--os-variant alpinelinux3.17 \
		--disk none \
		--pxe --network network=default \
		--install no_install=yes,kernel=$url/vmlinuz-$fla,initrd=$url/initramfs-$fla,kernel_args="$cmdline"
	# 	qemu-system-aarch64 -M virt -cpu cortex-a72 -accel tcg \
	# 		-m 1024 -smp 2 \
	# 		-nographic \
	# 		-boot d \
	# 		-L /usr/shae/AAVMF/AAVMF_CODE.fd \
	# 		-nic user,id=n1,net=192.168.222.0/24,hostfwd=tcp::8022-:22,bootfile=$bootp \
	# 		-drive media=cdrom,file=$iso,readonly=on
	#		-device e1000,netdev=n1
	# -device virtio-net-pci,netdev=net0
	# -netdev user,id=n1,tftp=/path/to/tftp/files,bootfile=/pxelinux.0

	return

	#		-netdev user,id=net0,net=192.168.222.0/24,hostfwd=tcp::8022-:22,bootfile=$BOOTP \
	#		-device virtio-net-pci,netdev=net0
	# -nographic \
}

ipxe() {
	kvm -cpu host -accel kvm \
		-m 1024 -smp 2 -boot n \
		-display curses -nographic \
		-monitor telnet:127.0.0.1:1234,server,nowait \
		-netdev user,id=net0,net=192.168.222.0/24,hostfwd=tcp::8022-:22,bootfile=$BOOTP \
		-device virtio-net-pci,netdev=net0
	# -echr 2 \
}

# aarch64
####################
# Main Prog.
####################
case "$arch" in
"x86_64")
	domain_type="kvm"
	console="ttyS0"
	machine='pc-i440fx-jammy'
	;;
"ppc64le")
	console="hvc0"
	machine="pseries"
	cpu="POWER10"
	;;
"aarch64")
	console="ttyAMA0"
	machine="virt"
	cpu="cortex-a76"
	;;
"armv7")
	# not working yet
	# not startup due to wrong arch
	console="ttyAMA0"
	# machine="raspi2b"
	machine="virt"
	cpu="cortex-a15"
	cpu_count=1
	os_arch="armv7l"
	dtb="dtb=/nfsroot/VMs/soft-pi/boot/bcm2710-rpi-2-b.dtb"
	ker_ver="rpi2"
	mem_size=1024
	# -net user,hostfwd=tcp::5022-:22 -net nic \
	;;
"s390x")
	# refer: https://wiki.qemu.org/Documentation/Platforms/S390X
	console="ttysclp0"
	machine="s390-ccw-virtio-7.2"
	cpu="max"
	# -device virtio-blk-ccw
	;;
*)
	echo "Syntax: $0 ARCH"
	echo "Where ARCH in: x86_64, aarch64, s390x, ppc64le, armv7, armhf"
	exit
	;;
esac

# Disk style could be in: minimum, zsh, adhole
disk="minimum"
#
nb_url="http://mirror.nju.edu.cn/alpine/latest-stable/releases/$vm_arch/netboot"
modloop_url="http://192.168.99.140/$vm_arch"
modloop="modloop=$modloop_url/modloop-$ker_ver"

# domain name you want to use
my_domain="$disk-$vm_arch-01"
# your kernel and initramfs downloaded dir name
my_dir="/nfsroot/VMs/alpine/netboot/$vm_arch"
[ ! -d "$my_dir" ] && mkdir -p $my_dir
# Web 端的 apkovl.tar.gz 的路径
apkovl="http://192.168.7.11/apkovl/${disk}.tar.gz"
# apkovl="https://apkovl:AdH0!e@apkovl.freelamp.com/adhole.apkovl.tar.gz"
# cmdline="modules=loop,squashfs,af_packet
cmdline="console=$console ip=dhcp $modloop apkovl=$apkovl $dtb"
#
# use the last autostart network as your network name
my_network="$(virsh -q net-list --autostart --name | tail -1)"
[ -z "$my_network" ] && echo "Error: Please define an autostart network first!" && exit 1
#
virsh domid $my_domain >/dev/null 2>&1
[ $? = 0 ] && echo "Info: $my_domain exist, undefine it first." && virsh undefine $my_domain
# define a 1c/2G VM, 2GB is needed for adhole to process over 1M blocking domains
cat <<EOF >/tmp/$my_domain.xml
<domain type='$domain_type'>
   <name>$my_domain</name>
   <metadata>
     <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
       <libosinfo:os id="http://alpinelinux.org/alpinelinux/3.17"/>
     </libosinfo:libosinfo>
   </metadata>
   <os>
     <type arch='$os_arch' machine='$machine'>hvm</type>
   </os>
   <memory unit='MiB'>$mem_size</memory>
   <currentMemory unit='MiB'>$mem_size</currentMemory>
   <vcpu placement='static'>$cpu_count</vcpu>
</domain>
EOF
virsh define /tmp/$my_domain.xml
[ $? != 0 ] && echo "Error: unable to define domain, please check: /tmp/$my_domain.xml" && exit 1
rm /tmp/$my_domain.xml && echo "Info: removed: /tmp/$my_domain.xml"
#
virt-xml $my_domain --edit --metadata description="This VM is auto-generated by $0, a script coined by LeisureLinux."
#
# Old way: virt-xml $my_domain --edit --xml ./os/kernel="$my_dir/vmlinuz-lts"
#
# add_kernel

[ $os_arch = "aarch64" ] && virt-xml $my_domain --edit --boot loader="/usr/share/AAVMF/AAVMF_CODE.fd"
[ $os_arch = "armv7l" ] && virt-xml $my_domain --edit --boot loader="/usr/share/AAVMF/AAVMF32_CODE.fd"
# [ $os_arch = "armv7l" ] && virt-xml $my_domain --edit --boot loader="/usr/lib/u-boot/qemu_arm/u-boot.bin"
# [ $os_arch = "armv7l" ] && virt-xml $my_domain --edit --boot loader="/usr/lib/ipxe/qemu/pxe-virtio.rom"
# [ $os_arch = "armv7l" ] &&
# virt-xml $my_domain --add-device --disk "/usr/lib/ipxe/ipxe.iso",device=cdrom

# [ $os_arch = "armv7l" ] && virt-xml $my_domain --edit --boot network
# qemu-system-arm -M virt -kernel ./vmlinuz -initrd ./initrd.gz -hda debian-3607.qcow2 -nographic -m 1024M -append "console=ttyAMA0" -drive file=debian-10.9.0-armhf-netinst.iso,id=cdrom,if=none,media=cdrom -device virtio-scsi-device -device scsi-cd,drive=cdrom
# -device usb-net,netdev=net0 -netdev user,id=net0,hostfwd=tcp::5555-:22

if [ "$arch" = "x86_64" ]; then
	virt-xml $my_domain --edit --cpu $cpu mode='host-passthrough'
else
	virt-xml $my_domain --edit --cpu $cpu
fi
# virt-xml $my_domain --edit --boot network

virt-xml $my_domain --add-device --network $my_network
[ $? != 0 ] && echo "Error: found error in network device add" && virsh undefine $my_domain && exit 4
# virt-xml $my_domain --add-device --network type=user,rom.file=/usr/lib/ipxe/snp.efi

virt-xml $my_domain --add-device --console pty,target_type=virtio
virt-xml $my_domain --add-device --channel unix,target_type=virtio
virt-xml $my_domain --add-device --serial pty,target_type=isa-serial
[ $? != 0 ] && echo "Error: found error in adding serial device" && virsh undefine $my_domain && exit 5
echo
echo "Domain $my_domain defined!"

# 下载最新版本的支持 netboot 的内核和initrd:
[ ! -r $my_dir/vmlinuz-$ker_ver ] && axel -o $my_dir $nb_url/vmlinuz-$ker_ver
[ ! -r $my_dir/initramfs-$ker_ver ] && axel -o $my_dir $nb_url/initramfs-$ker_ver
