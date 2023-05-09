#!/bin/sh
# Run minimal Linux with BusyBox on RISC-V from Source
# Last modified: Tue May  9 16:04:39 CST 2023
# Bilibili Video URL: To-Be-Filled
# Besides package qemu-system-misc
#
BITS=64
# VM vcpu and ram size
VCPU=2
RAM="64M"
#
# ####################################################################

# check package:
# git zstd axel opensbi u-boot-qemu
#
build_kernel() {
	KER_VER="6.1.27"
	KER_DIR=$HOME/github/
	KER="$KER_DIR/linux-${KER_VER}/arch/$ARCH/boot/Image"
	[ -r "$KER" ] && return
	#
	[ ! -d $KER_DIR ] && mkdir -p $KER_DIR
	KER_URL="https://mirror.nju.edu.cn/kernel/v6.x/linux-${KER_VER}.tar.gz"
	# https://gist.github.com/chrisdone/02e165a0004be33734ac2334f215380e
	if [ ! -d $KER_DIR/$(basename $KER_URL .tar.gz) ]; then
		axel -o /var/tmp $KER_URL
		echo "Info: decompressing $KER_URL to $KER_DIR ..."
		tar xf /var/tmp/$(basename $KER_URL) -C $KER_DIR
		rm /var/tmp/$(basename $KER_URL)
	fi
	cd $KER_DIR/$(basename $KER_URL .tar.gz)
	make ARCH=$ARCH CROSS_COMPILE=$PREFIX defconfig
	make ARCH=$ARCH CROSS_COMPILE=$PREFIX -j$(nproc)
}

compile_busybox() {
	CMP="CROSS_COMPILE=${PREFIX}"
	LD="LDFLAGS=--static"
	echo "Info: Compiling busybox and install to $ROOT ..."
	cd $BUSY
	sudo $CMP $LD make -C . -j $(nproc) install CONFIG_PREFIX=$ROOT
}

qemu_busybox() {
	$QEMU -nographic -machine virt \
		-no-reboot -nographic -m $RAM -smp cores=$VCPU \
		-kernel $KER \
		-drive file=$IMG,format=raw,id=hd0 \
		-device virtio-blk-device,drive=hd0 \
		-append "root=/dev/vda rw earlyprintk console=ttyS0,115200" \
		-netdev user,id=eth0 \
		-device virtio-net-device,netdev=eth0
}

ubuntu_riscv() {
	# Bilibili URL: https://www.bilibili.com/video/BV1NS4y1z7uS/
	# -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
	# -device virtio-net-device,netdev=net0 \
	# Download Image from: https://ubuntu.com/download/risc-v
	local URL="https://mirror.sjtu.edu.cn/ubuntu-cdimage/releases/23.04/release/ubuntu-23.04-preinstalled-server-riscv64+unmatched.img.xz"
	local fn=$(basename $URL)
	# Initial login: ubuntu/ubuntu
	DISK=$VM_DIR/$(basename $fn .xz)
	if [ ! -r "$DISK" ]; then
		axel -o $VM_DIR $URL
		[ $? != 0 ] && echo "Error: Download failed!" && exit 1
		echo "Info: decompressing $VM_DIR/$fn ..."
		unxz $VM_DIR/$fn
	fi
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
}

debian_riscv() {
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
	if [ ! -r $DISK ]; then
		axel -o $VM_DIR/dqib_riscv64-virt.zip "https://gitlab.com/api/v4/projects/giomasce%2Fdqib/jobs/artifacts/master/download?job=convert_riscv64-virt"
		unzip $VM_DIR/dqib_riscv64-virt.zip -d $VM_DIR
	fi
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

arch_loongarch() {
	# Bilibili video for this part: https://www.bilibili.com/video/BV17c411K7ng/
	QEMU="/usr/local/bin/qemu-system-loongarch64"
	LOONG_URL="https://mirror.nju.edu.cn/loongarch/archlinux/images/"
	BIOS="QEMU_EFI_7.2.fd"
	[ ! -r $VM_DIR/$BIOS ] && axel -o $VM_DIR ${LOONG_URL}${BIOS}
	DISK="archlinux-minimal-2022.12.02-loong64.qcow2"
	[ ! -r $VM_DIR/$DISK ] && axel -o $VM_DIR ${LOONG_URL}${DISK}.zst && zstd -d --rm $VM_DIR/${DISK}.zst
	# Build Loongson Qemu:
	# git clone https://github.com/loongson/qemu.git
	# ./configure  --target-list=loongarch64-softmmu,loongarch64-linux-user --enable-slirp --enable-spice
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
		-bios $VM_DIR/$BIOS \
		-serial stdio \
		-device virtio-gpu-pci \
		-nic user,hostfwd=tcp::2222-:22 \
		-device nec-usb-xhci,id=xhci,addr=0x1b \
		-device usb-tablet,id=tablet,bus=xhci.0,port=1 \
		-device usb-kbd,id=keyboard,bus=xhci.0,port=2 \
		-hda $VM_DIR/$DISK \
		-device virtio-serial-pci \
		-spice port=5930,disable-ticketing=on \
		-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
		-chardev spicevmc,id=spicechannel0,name=vdagent
}

setup_busybox() {
	build_kernel
	# Disk image size in Mib
	SIZE=16
	cd $BUSY
	echo "Info: filling zero to $IMG"
	sudo dd if=/dev/zero of=$IMG bs=1M count=$SIZE
	echo "Info: formating $IMG"
	sudo mkfs.ext4 $IMG
	mkdir -p $ROOT
	sudo mount $IMG $ROOT
	[ $? != 0 ] && echo "Error: mount $IMG failed!" && exit 5
	compile_busybox
	sudo mkdir -p $ROOT/proc/sys/kernel
	sudo touch $ROOT/etc/fstab
	sudo mkdir -p $ROOT/etc/init.d
	# sudo mkdir $ROOT/dev
	cd $ROOT/dev
	# sudo mkdir $ROOT/dev/pts $ROOT/dev/shm
	sudo mknod sda b 8 0
	sudo mknod console c 5 1
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
# Mount system
mkdir /sys /dev
mount -t devtmpfs  devtmpfs  /dev
mount -t proc      proc      /proc
mount -t sysfs     sysfs     /sys

# https://git.busybox.net/busybox/tree/docs/mdev.txt?h=1_32_stable
# echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s
#
export TZ=CST-8
ifconfig lo up
udhcpc -i eth0 2>/dev/null
telnetd -l /bin/sh
hostname $HOSTNAME
echo "  ** Press Ctr-A X to exit BusyBox when in Qemu **"
# Busybox TTY fix
setsid cttyhack sh
EOF
	#
	sudo chmod +x $ROOT/etc/init.d/rcS
	sudo mkdir -p $ROOT/usr/share/udhcpc
	sudo cp $BUSY/examples/udhcp/simple.script $ROOT/usr/share/udhcpc/default.script
	cat $BUSY/examples/inittab | sudo tee $ROOT/etc/inittab
	# # Install busybox applets as symlinks
	# /bin/busybox --install -s /bin
	#
	sudo umount $ROOT
	sudo chown $USER $IMG
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
	ARCH="riscv"
	VM_DIR="/opt/VMs/$ARCH"
	QEMU="qemu-system-${ARCH}${BITS}"
	[ ! -d $VM_DIR ] && sudo mkdir -p $VM_DIR && sudo chown $USER $VM_DIR
	debian_riscv
	;;
"ubuntu")
	ARCH="riscv"
	VM_DIR="/opt/VMs/$ARCH"
	QEMU="qemu-system-${ARCH}${BITS}"
	[ ! -d $VM_DIR ] && sudo mkdir -p $VM_DIR && sudo chown $USER $VM_DIR
	ubuntu_riscv
	;;
"arch")
	ARCH="loongarch"
	VM_DIR="/opt/VMs/$ARCH"
	QEMU="qemu-system-${ARCH}${BITS}"
	[ ! -d $VM_DIR ] && sudo mkdir -p $VM_DIR && sudo chown $USER $VM_DIR
	arch_loongarch
	;;
*)
	ARCH="riscv"
	# hostname of the VM, and the image filename will be named in hostname
	HOSTNAME="$ARCH-01"
	#
	QEMU="qemu-system-${ARCH}${BITS}"
	# busybox source folder
	BUSY="$HOME/busybox"
	# Define your kernel path here
	#
	# Output dir, disk image will write to this directory
	VM_DIR="/opt/VMs/$ARCH"
	[ ! -d $VM_DIR ] && sudo mkdir -p $VM_DIR && sudo chown $USER $VM_DIR
	IMG="$VM_DIR/busybox-${HOSTNAME}.img"
	# PREFIX="${ARCH}${BITS}-unknown-linux-gnu-"
	PREFIX="${ARCH}${BITS}-linux-gnu-"
	# Just the mount point
	ROOT="$BUSY/mnt"
	if [ ! -x "$(which ${PREFIX}gcc)" ]; then
		echo "Install gcc-${ARCH}${BITS}-linux-gnu package first ..."
		sudo apt install gcc-${ARCH}${BITS}-linux-gnu
	fi
	# clone busybox source code
	[ ! -d "$BUSY" ] && git clone --depth=1 https://github.com/mirror/busybox.git $BUSY
	if [ ! -r $BUSY/.config ]; then
		echo "Please initilize source code first, by run:"
		echo "cd $BUSY; $CMP $LD make defconfig; cd -"
		exit
	fi

	setup_busybox
	qemu_busybox
	;;
esac
