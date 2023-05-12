#!/bin/sh
# Run minimal Linux with BusyBox on RISC-V from Source
# Other stuffs, jump to bottom to read
# Last modified: Tue May  9 16:04:39 CST 2023
# Bilibili Video URL: To-Be-Filled
# Todo: BusyBox for aarch64,loongarch64
BITS=64
# VM vcpu and ram size
VCPU=2
RAM="64M"
KER_VER="6.1.27"
# Place your kernel source to $KER_DIR
KER_DIR="$HOME/github"
[ ! -d $KER_DIR ] && mkdir -p $KER_DIR
KER_URL=$SJTU"kernel/v6.x/linux-${KER_VER}.tar.gz"
SJTU="http://mirror.sjtu.edu.cn/"
NJU="http://mirror.nju.edu.cn/"
#
# ####################################################################

if [ ! -r $HOME/.cache/.qemu.installed ]; then
	echo "Check to install required packages"
	sudo apt install git zstd axel opensbi \
		u-boot-qemu guestfs-tools qemu-system-misc
	[ $? = 0 ] && touch $HOME/.cache/.qemu.installed
fi
#

ker_dir() {
	KER="$KER_DIR/linux-${KER_VER}/arch/$1/boot/Image"
}

build_kernel() {
	ker_dir $1
	echo "Debug: Destine output Image file: $KER"
	# KER="$KER_DIR/linux-${KER_VER}/arch/$ARCH/boot/Image"
	[ -r "$KER" ] && return
	local a="$ARCH"
	#
	# https://gist.github.com/chrisdone/02e165a0004be33734ac2334f215380e
	if [ ! -d $KER_DIR/$(basename $KER_URL .tar.gz) ]; then
		axel -o /var/tmp $KER_URL
		echo "Info: decompressing $KER_URL to $KER_DIR ..."
		tar xf /var/tmp/$(basename $KER_URL) -C $KER_DIR
		rm /var/tmp/$(basename $KER_URL)
	fi
	cd $KER_DIR/$(basename $KER_URL .tar.gz)
	local conf="defconfig"
	[ "$a" = "mips" ] && local conf="malta_kvm_defconfig"
	# [ "$a" = "arm" ] && local a="arm64"
	make ARCH=$a CROSS_COMPILE=$PREFIX $conf
	[ $? != 0 ] && echo "Error: compile kernel failed!" && exit 11
	make ARCH=$a CROSS_COMPILE=$PREFIX -j$(nproc)
	[ $? != 0 ] && echo "Error: compile kernel failed!" && exit 11
}

compile_busybox() {
	CMP="CROSS_COMPILE=${PREFIX}"
	LD="LDFLAGS=--static"
	echo "Info: Compiling busybox and install to $ROOT ..."
	cd $BUSY
	sudo $CMP $LD make -C . -j $(nproc) install CONFIG_PREFIX=$ROOT
	[ $? != 0 ] && echo "Error: compile busybox failed!" && exit 12
}

qemu_sparc() {
	# After boot up under OBP ok prompt, input "boot -v", login with root
	# without password, run psrinfo check cpu info.
	local dir="$VM_DIR/OpenSparcT1"
	if [ ! -d "$dir/S10image" ]; then
		mkdir -p $dir
		# Download image from Oracle
		local url="http://download.oracle.com/technetwork/systems/opensparc/OpenSPARCT1_Arch.1.5.tar.bz2"
		local fn=$(basename $url)
		axel -o $dir $url
		tar xf $dir/$fn -C $dir
	fi
	$QEMU -M niagara -L $dir/S10image/ \
		-nographic -m 256 \
		-drive if=pflash,readonly=on,file=$dir/S10image/disk.s10hw2
}

qemu_mips() {
	# To be test
	# automate u-boot compile
	# CROSS_COMPILE=mips64-linux-gnuabi64- make malta64_defconfig
	# mv u-boot-dtb.bin ../linux-6.1.27/arch/mips/boot/u-boot.bin
	sudo mkdir -p $VM_DIR/tftproot
	ker_dir mips
	local bios="$(dirname $KER)/u-boot.bin"
	$QEMU -m 256 -cpu MIPS64R2-generic -M malta -bios $bios \
		-nographic \
		-netdev user,id=net0,tftp="$VM_DIR/tftproot" \
		-device pcnet,netdev=net0
	# -drive if=pflash,file="$(dirname $KER)/u-boot",format=raw
}

qemu_pi() {
	# Login with root without password
	TTY="ttyAMA0"
	local CPU="cortex-a72"
	local NAME="softpi4-01"
	# Download image, have no explicit mirror, but looked like itself had CDN
	local url="https://raspi.debian.net/tested/20230101_raspi_4_bookworm.img.xz"
	local fn=$(basename $url)
	local DISK="$VM_DIR/$(basename $fn .xz)"
	if [ ! -r "$DISK" ]; then
		axel $url -o $VM_DIR
		[ $? != 0 ] && echo "Error: failed to download $url to $DISK!" && exit 1
		echo "Info: decompressing $DISK.xz ..."
		unxz -d $DISK.xz
	fi
	[ ! -d "$VM_DIR/$NAME" ] && mkdir $VM_DIR/$NAME
	local kernel="$VM_DIR/$NAME/vmlinuz-6.0.0-6-arm64"
	local initrd="$VM_DIR/$NAME/initrd.img-6.0.0-6-arm64"
	if [ ! -r $kernel ]; then
		echo "Info: Extract kernel and initrd from $DISK"
		sudo virt-get-kernel -a $DISK -o $VM_DIR/$NAME
		[ $? != 0 ] && echo "Error: failed to get kernel image from $DISK" && exit 2
	fi
	sudo $QEMU -no-reboot -nographic \
		-M virt -cpu $CPU -m 4G -smp 4 \
		--name $NAME -pidfile /run/$NAME.pid \
		-kernel $kernel -initrd $initrd \
		-append "console=$TTY root=/dev/vda2 noresume rw" \
		-device virtio-blk,drive=hd0,bootindex=0 \
		-drive file=$DISK,format=raw,if=none,id=hd0,cache=writeback \
		-device virtio-net-device,netdev=net \
		-netdev user,id=net,hostfwd=tcp::2222-:22
}

riscv_busybox() {
	[ -n "$maxcpu" ] && local VCPU=$maxcpu
	echo "Debug: $QEMU machine:$machine IMG:$IMG Kernel:$KER"
	sleep 2
	$QEMU -nographic -machine $machine \
		-no-reboot -nographic -m $RAM -smp cores=$VCPU \
		-device virtio-blk-device,drive=hd0 \
		-drive file=$IMG,format=raw,id=hd0 \
		-initrd $IMG \
		-kernel $KER \
		-append "root=/dev/vda rw earlyprintk console=ttyS0,115200" \
		-device virtio-net-device,netdev=eth0 \
		-netdev user,id=eth0
}

riscv_ubuntu() {
	# Bilibili URL: https://www.bilibili.com/video/BV1NS4y1z7uS/
	# -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
	# -device virtio-net-device,netdev=net0 \
	# Download Image from: https://ubuntu.com/download/risc-v
	local url=$SJTU"ubuntu-cdimage/releases/23.04/release/ubuntu-23.04-preinstalled-server-riscv64+unmatched.img.xz"
	local fn=$(basename $url)
	# Initial login: ubuntu/ubuntu
	DISK=$VM_DIR/$(basename $fn .xz)
	if [ ! -r "$DISK" ]; then
		axel -o $VM_DIR $url
		[ $? != 0 ] && echo "Error: Download failed!" && exit 1
		echo "Info: decompressing $VM_DIR/$fn ..."
		unxz $VM_DIR/$fn
	fi
	$QEMU -boot d -no-reboot -nographic \
		-m 2G -smp cpus=4,cores=4 -M virt \
		-bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_dynamic.elf \
		-kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
		-append 'root=/dev/vda rw console=ttyAMA0 rootwait earlyprintk' \
		-device virtio-blk-device,drive=blk0 \
		-drive file=$DISK,format=raw,if=none,id=blk0,aio=native,cache=none \
		-device virtio-net-device,netdev=net \
		-netdev user,id=net,hostfwd=tcp::2222-:22 \
		-object rng-random,filename=/dev/urandom,id=rng0 \
		-device virtio-rng-device,rng=rng0
}

riscv_debian() {
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

loongarch_arch() {
	# Bilibili video for this part: https://www.bilibili.com/video/BV17c411K7ng/
	QEMU="qemu-system-loongarch64"
	local URL=$MIRROR"loongarch/archlinux/images/"
	BIOS="QEMU_EFI_7.2.fd"
	[ ! -r $VM_DIR/$BIOS ] && axel -o $VM_DIR ${URL}${BIOS}
	DISK="archlinux-minimal-2023.05.10-loong64.qcow2"
	[ ! -r $VM_DIR/$DISK ] && axel -o $VM_DIR ${URL}${DISK}.zst && zstd -d --rm $VM_DIR/${DISK}.zst
	# Build Loongson Qemu:
	# git clone https://github.com/loongson/qemu.git
	# ./configure  --target-list=loongarch64-softmmu,loongarch64-linux-user --enable-slirp --enable-spice
	# make && sudo make install
	# for the minimal image, use pacman -Syu update OS first
	# then pacman -S openssh vim && sudo systemctl --now enable sshd
	# To enable Ctr-L, add "set -o emacs" to /etc/profile, re-login
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
	local ker_conf=$ARCH
	build_kernel $ker_conf
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

qemu_pkgs() {
	# qemu-guest-agent
	local a=$1
	case $(echo "$a" | cut -c1-3) in
	arm)
		pkg="qemu-system-arm"
		gnu="gcc-aarch64-linux-gnu"
		machine="virt"
		;;
	mip)
		# need package u-boot-tools to build u-boot image
		pkg="qemu-system-mips"
		gnu="mips64-linux-gnuabi64"
		prefix="mips64-linux-gnuabi64-"
		machine="malta"
		# Supported machines are:
		# magnum   malta   mipssim pica61
		;;
	ppc)
		pkg="qemu-system-ppc"
		gnu="gcc-powerpc64-linux-gnu"
		;;
	spa)
		pkg="qemu-system-sparc"
		gnu="gcc-sparc64-linux-gnu"
		# niagara,sun4u,sun4v
		machine="niagara"
		maxcpu=1
		;;
	x86)
		pkg="qemu-system-x86"
		gnu="gcc-x86-64-linux-gnu"
		;;
	s39)
		pkg="qemu-system-s390x"
		gnu="gcc-s390x-linux-gnu"
		;;
	*)
		pkg="qemu-system-misc"
		gnu="gcc-riscv64-linux-gnu"
		machine="virt"
		;;
	esac
}

# Main Prog.
#
case $1 in
"debian")
	ARCH="riscv"
	VM_DIR="/opt/VMs/$ARCH"
	QEMU="qemu-system-${ARCH}${BITS}"
	[ ! -d $VM_DIR ] && sudo mkdir -p $VM_DIR && sudo chown $USER $VM_DIR
	riscv_debian
	;;
"ubuntu")
	ARCH="riscv"
	VM_DIR="/opt/VMs/$ARCH"
	QEMU="qemu-system-${ARCH}${BITS}"
	[ ! -d $VM_DIR ] && sudo mkdir -p $VM_DIR && sudo chown $USER $VM_DIR
	riscv_ubuntu
	;;
"sparc")
	ARCH="sparc"
	QEMU="qemu-system-${ARCH}${BITS}"
	VM_DIR="/opt/VMs/$ARCH"
	qemu_sparc
	;;
"mips")
	ARCH="mips"
	VM_DIR="/opt/VMs/$ARCH"
	QEMU="qemu-system-${ARCH}${BITS}"
	qemu_mips
	;;

"pi")
	ARCH="arm"
	VM_DIR="/opt/VMs/$ARCH"
	# qemu_pkgs $ARCH
	[ ! -d $VM_DIR ] && sudo mkdir -p $VM_DIR && sudo chown $USER $VM_DIR
	QEMU="qemu-system-aarch${BITS}"
	# PREFIX="aarch${BITS}-linux-gnu-"
	# IMG="$VM_DIR/busybox-${HOSTNAME}.img"
	qemu_pi
	;;

"loongarch")
	ARCH="loongarch"
	VM_DIR="/opt/VMs/$ARCH"
	QEMU="qemu-system-${ARCH}${BITS}"
	[ ! -d $VM_DIR ] && sudo mkdir -p $VM_DIR && sudo chown $USER $VM_DIR
	loongarch_arch
	;;

"busybox")
	ARCH="$1"
	[ -z "$ARCH" ] && echo "Syntax: $0 architecture" && exit 1
	# hostname of the VM, and the image filename will be named in hostname
	HOSTNAME="$ARCH-01"
	#
	QEMU="qemu-system-${ARCH}${BITS}"
	PREFIX="${ARCH}${BITS}-linux-gnu-"
	qemu_pkgs $ARCH
	[ ! -x "$(which $QEMU)" ] && echo "Error: $QEMU not found! You may need to install $pkg" && exit 2
	#
	# busybox source folder
	BUSY="$HOME/busybox"
	# Output dir, disk image will write to this directory
	VM_DIR="/opt/VMs/BusyBox/$ARCH"
	[ ! -d $VM_DIR ] && sudo mkdir -p $VM_DIR && sudo chown $USER $VM_DIR
	#
	IMG="$VM_DIR/busybox-${HOSTNAME}.img"
	[ -n "$prefix" ] && PREFIX=$prefix
	# Just the mount point
	ROOT="$BUSY/mnt"
	if [ ! -x "$(which ${PREFIX}gcc)" ]; then
		echo "Info: Install $gnu first ..."
		sudo apt install $gnu
		[ $? != 0 ] && echo "Error: install $gnu" && exit 3
	fi
	# clone busybox source code
	[ ! -d "$BUSY" ] && git clone --depth=1 https://github.com/mirror/busybox.git $BUSY
	if [ ! -r $BUSY/.config ]; then
		echo "Please initilize source code first, by run:"
		echo "cd $BUSY; $CMP $LD make defconfig; cd -"
		exit
	fi
	setup_busybox
	riscv_busybox
	;;
*)
	echo "$0 pi|mips|sparc|loongarch|busybox|debian|ubuntu"
	echo "busybox, debian, ubuntu emulate on riscv64 target"
	echo "pi(aarch64) is on debian, loongarch is on archlinux, sparc on Solaris 10(T1)"
	;;
esac
