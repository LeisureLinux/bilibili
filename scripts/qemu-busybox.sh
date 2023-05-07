#!/bin/sh
# Run minimal Linux with BusyBox on RISC-V from Source
# Last modified: 2023年 05月 07日 星期日 10:52:58 CST
# Bilibili Video URL: To-Be-Filled
# Besides package qemu-system-misc
# If to run Ubuntu, pre-requist: $ sudo apt install opensbi u-boot-qemu
#
ARCH="riscv"
# ARCH="loongarch"
BITS=64
# PREFIX="${ARCH}${BITS}-unknown-linux-gnu-"
PREFIX="${ARCH}${BITS}-linux-gnu-"
KERNEL_VER="6.1.27"

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
# clone source code [ ! -d "$BUSY" ] && git clone --depth=1 https://github.com/mirror/busybox.git $BUSY
if [ ! -r $BUSY/.config ]; then
	echo "Please initilize source code first, by run:"
	echo "cd $BUSY; $CMP $LD make defconfig; cd -"
	exit
fi
# Just the mount point
ROOT="$BUSY/mnt"
# Output dir, disk image will write to this directory
DIR="/opt/busybox"
[ ! -d $DIR ] && sudo mkdir -p $DIR
#
IMG="$DIR/busybox-${HOSTNAME}.img"
#

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
	qemu-system-${ARCH}${BITS} -nographic -machine virt \
		-no-reboot -nographic -m $RAM -smp cores=$VCPU \
		-kernel $KERNEL \
		-drive file=$IMG,format=raw,id=hd0 \
		-device virtio-blk-device,drive=hd0 \
		-append "root=/dev/vda rw earlyprintk console=ttyS0,115200" \
		-netdev user,id=eth0 \
		-device virtio-net-device,netdev=eth0
}

#
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
# find . | cpio -H newc -o | gzip -9 >$IMG
if [ $? = 0 ]; then
	echo "busybox image: $IMG generated"
	sudo chown $USER $IMG
	qemu_busybox
else
	echo "Error: failed"
fi

demo() {
	# start x86_64 image:
	qemu-system-x86_64 -kernel arch/x86_64/boot/bzImage \
		-nographic -initrd busybox/busybox.img \
		-append "console=ttyS0" -m 512 --enable-kvm
}
