#!/bin/sh
# Run minimal Linux with BusyBox on RISC-V from Source
# Last modified: 2023年 05月 07日 星期日 10:52:58 CST
# Bilibili Video URL: To-Be-Filled
# Besides package qemu-system-misc
# If to run Debian/Ubuntu, pre-requist: $ sudo apt install opensbi u-boot-qemu
#
ARCH="riscv"
# ARCH="loongarch"
BITS=64
# PREFIX="${ARCH}${BITS}-unknown-linux-gnu-"
PREFIX="${ARCH}${BITS}-linux-gnu-"
KERNEL_VER="6.1.27"
QEMU="qemu-system-${ARCH}${BITS}"

# Disk image size in Mib
SIZE=16
# VM vcpu and ram size
VCPU=2
RAM="64M"
# hostname of the VM, and the image filename will be named in hostname
# HOSTNAME="loongarch-01"
HOSTNAME="$ARCH-01"
#
CMP="CROSS_COMPILE=${PREFIX}"
LD="LDFLAGS=--static"
#
BUSY="$HOME/busybox"
# clone source code
[ ! -d "$BUSY" ] && git clone --depth=1 https://github.com/mirror/busybox.git $BUSY
if [ ! -r $BUSY/.config ]; then
	echo "Please initilize source code first, by run:"
	echo "cd $BUSY; $CMP $LD make defconfig; cd -"
	exit
fi

# Output dir, disk image will write to this directory
VM_DIR="/nfsroot/VMs/$ARCH"
[ ! -d $VM_DIR ] && sudo mkdir -p $VM_DIR
#
IMG="$VM_DIR/busybox-${HOSTNAME}.img"
#
# Just the mount point
ROOT="$BUSY/mnt"

build_kernel() {
	# Use axel to download the kernel from
	# https://mirror.nju.edu.cn/kernel/v6.x/linux-6.1.27.tar.gz
	# make ARCH=$ARCH CROSS_COMPILE=$PREFIX defconfig
	# make ARCH=$ARCH CROSS_COMPILE=$PREFIX -j$(nproc)
	# Once compiled, use KERNEL=linux-6.1.27/arch/riscv/boot/Image
	# Define your kernel path here
	KERNEL=$HOME/github/linux-${KERNEL_VER}/arch/$ARCH/boot/Image
	[ ! -r "$KERNEL" ] && echo "Error: failed to read $KERNEL image" && exit 1
}

compile_busybox() {
	echo "Info: Compiling busybox and install to $ROOT ..."
	cd $BUSY
	sudo $CMP $LD make -C . -j $(nproc) install CONFIG_PREFIX=$ROOT
}

qemu_busybox() {
	$QEMU -nographic -machine virt \
		-no-reboot -nographic -m $RAM -smp cores=$VCPU \
		-kernel $KERNEL \
		-drive file=$IMG,format=raw,id=hd0 \
		-device virtio-blk-device,drive=hd0 \
		-append "root=/dev/vda rw earlyprintk console=ttyS0,115200" \
		-netdev user,id=eth0 \
		-device virtio-net-device,netdev=eth0
}

qemu_ubuntu() {
	# Bilibili URL: https://www.bilibili.com/video/BV1NS4y1z7uS/
	# -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
	# -device virtio-net-device,netdev=net0 \
	# Download Image from: https://ubuntu.com/download/risc-v
	# 23.04 URL:
	# https://mirror.nju.edu.cn/ubuntu-cdimage/releases/23.04/release/ubuntu-23.04-preinstalled-server-riscv64%2Bunmatched.img.xz
	# Initial login: ubuntu/ubuntu
	DISK="$VM_DIR/ubuntu-23.04-preinstalled-server-riscv64+unmatched.img"
	$QEMU -boot d -no-reboot -nographic \
		-m 2G -smp cpus=4,cores=4 -M virt \
		-bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_dynamic.elf \
		-kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
		-object rng-random,filename=/dev/urandom,id=rng0 \
		-device virtio-net-device,netdev=net \
		-netdev user,id=net,hostfwd=tcp::2222-:22 \
		-device virtio-rng-device,rng=rng0 \
		-device virtio-blk-device,drive=blk0 \
		-drive file=$DISK,format=raw,if=none,id=blk0,aio=native,cache=none \
		-append 'root=/dev/vda rw console=ttyAMA0 rootwait earlyprintk'
	# echo "Cleanup tap"
	# sudo tunctl -d tap0
}

qemu_debian() {
	# Download Image from: https://people.debian.org/~gio/dqib/
	# Unzip it, startup, and login with root/root
	# use nano to update the sourc.list to mirror.nju.edu.cn
	# apt install vim sudo psmisc locales zstd file
	# # usermod -G sudo debian
	# echo "127.0.1.1 $(hostname)" >> /etc/hosts
	# use ssh debian@localhost -p 2222 login from ssh (password is debian)
	# sudo dpkg-reconfigure locales
	# sudo unlink /etc/localtime
	# sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	# Or: Run 'dpkg-reconfigure tzdata'
	#
	DISK="$VM_DIR/dqib_riscv64-virt/image.qcow2"
	$QEMU -machine virt -m 1G -smp 8 -cpu rv64 \
		-device virtio-blk-device,drive=hd \
		-drive file=$DISK,if=none,id=hd \
		-device virtio-net-device,netdev=net \
		-netdev user,id=net,hostfwd=tcp::2222-:22 \
		-bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.elf \
		-kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
		-object rng-random,filename=/dev/urandom,id=rng \
		-device virtio-rng-device,rng=rng \
		-nographic -append "root=LABEL=rootfs console=ttyS0"
}

qemu_arch_loong() {
	# Download bios and qcow2 from: https://mirrors.wsyu.edu.cn/loongarch/archlinux/images/
	QEMU="qemu-system-loongarch64"
	VM_DIR="$VM_DIR/../loong"
	DISK="$VM_DIR/archlinux-mate-2022.12.03-loong64.qcow2"
	# Build Loongson Qemu:
	# git clone https://github.com/loongson/qemu.git
	# ./configure  --target-list=loongarch64-softmmu,loongarch64-linux-user --enable-slirp
	# make && sudo make install
	# -smp n,sockets=s,cores=c,threads=t
	# n = total number of threads in the whole system
	# s = total number of sockets in the system
	# c = number of cores per socket
	# t = number of threads per core
	# Todo:
	# * Check Why only see one CPU online.
	# * Try to compile edk2 to generate a 8.0 version .fd
	$QEMU -machine virt -m 4G \
		-smp 4,sockets=4,cores=1,threads=1 \
		-cpu la464-loongarch-cpu \
		-accel tcg,thread=multi \
		-bios $VM_DIR/QEMU_EFI_7.2.fd \
		-serial stdio \
		-device virtio-gpu-pci \
		-nic user,hostfwd=tcp::2222-:22 \
		-device nec-usb-xhci,id=xhci,addr=0x1b \
		-device usb-tablet,id=tablet,bus=xhci.0,port=1 \
		-device usb-kbd,id=keyboard,bus=xhci.0,port=2 \
		-hda $DISK \
		-device virtio-serial-pci -spice port=5930,disable-ticketing=on \
		-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
		-chardev spicevmc,id=spicechannel0,name=vdagent
}

setup_busybox() {
	build_kernel
	cd $BUSY
	echo "Info: filling zero to $IMG"
	sudo dd if=/dev/zero of=$IMG bs=1M count=$SIZE
	echo "Info: formating $IMG"
	sudo mkfs.ext4 $IMG
	mkdir -p $ROOT
	sudo mount $IMG $ROOT
	compile_busybox
	sudo mkdir -p $ROOT/proc $ROOT/sys $ROOT/dev $ROOT/root
	sudo mkdir -p $ROOT/etc
	sudo touch $ROOT/etc/fstab
	sudo mkdir -p $ROOT/etc/init.d
	#
	cat <<EOF | sudo tee $ROOT/etc/init.d/rcS
#!/bin/sh
# rcS scripts
echo  
echo "   Welcome to RISC-V World!"
echo " _         _                    _     _                  "
echo "| |    ___(_)___ _   _ _ __ ___| |   (_)_ __  _   ___  __"
echo "| |   / _ \ / __| | | | '__/ _ \ |   | | '_ \| | | \ \/ /"
echo "| |__|  __/ \__ \ |_| | | |  __/ |___| | | | | |_| |>  < "
echo '|_____\___|_|___/\__,_|_|  \___|_____|_|_| |_|\__,_/_/\_\\'
echo
mkdir -p /dev/pts
mkdir -p /dev/shm
mount -t sysfs sysfs /sys
mount -t proc nodev,proc /proc
mount -t devpts devpts /dev/pts
mount -t tmpfs tmpfs /dev/shm
ifconfig lo up
udhcpc -i eth0 2>/dev/null
telnetd -l /bin/sh
hostname $HOSTNAME
echo "  ** Press Ctr-A X to exit BusyBox when in Qemu **"
EOF
	#
	sudo chmod +x $ROOT/etc/init.d/rcS
	sudo mkdir -p $ROOT/usr/share/udhcpc
	sudo cp $BUSY/examples/udhcp/simple.script $ROOT/usr/share/udhcpc/default.script

	cat $BUSY/examples/inittab | sudo tee $ROOT/etc/inittab
	# Todo: Let inittab show login screen
	# echo "::respawn:/sbin/getty -L ttyS0 115200 ansi" | sudo tee -a $ROOT/etc/inittab
	# echo "console::respawn:/sbin/getty ttyS0 115200 ansi" | sudo tee -a $ROOT/etc/inittab
	# echo "console::respawn:/sbin/getty console 115200 ansi" | sudo tee -a $ROOT/etc/inittab
	# echo "::respawn:-/bin/sh" | sudo tee -a $ROOT/etc/inittab
	# create group file
	# echo "root:x:0:" | sudo tee $ROOT/etc/group
	# echo "root::0:0:root:/root:/bin/sh" | sudo tee $ROOT/etc/passwd
	# echo "root::19055:0:99999:7:::" | sudo tee $ROOT/etc/shadow
	# sudo chmod 644 $ROOT/etc/passwd $ROOT/etc/group
	# sudo chmod 600 $ROOT/etc/shadow
	#
	sudo umount $ROOT
	# Old way to generate image
	# find . | cpio -H newc -o | gzip -9 >$IMG
}

qemu_x86() {
	# start x86_64 image, not tested yet.
	qemu-system-x86_64 -kernel arch/x86_64/boot/bzImage \
		-nographic -initrd busybox/busybox.img \
		-append "console=ttyS0" -m 512 --enable-kvm
}

# Main Prog.
#
case $1 in
"debian")
	qemu_debian
	;;
"ubuntu")
	qemu_ubuntu
	;;
"arch")
	qemu_arch_loong
	;;
*)
	setup_busybox
	qemu_busybox
	;;
esac
