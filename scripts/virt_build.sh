#!/bin/sh
# My own virt-build small script
# Tested on OS=debian-11
# Need to run "chmod +r /boot/vmlinuz" on host if not root user

OS="$1"
HOSTNAME="$1-99"
# 当前用户名作为镜像内的用户名
UM="$USER"
# 镜像格式：qcow2 or raw
FORMAT="qcow2"
# 镜像文件名
IMG_FN="$HOSTNAME.$FORMAT"

DEB_APT_SRC="
deb http://ftp.cn.debian.org/debian bullseye main
deb http://security.debian.org/debian-security bullseye-security main
deb http://ftp.cn.debian.org/debian bullseye-updates main
deb http://ftp.cn.debian.org/debian bullseye-backports main
"

# Set DEBUG="-v" if needed
# export LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1
DEBUG="-v"
#
time sudo all_proxy=http://192.168.7.11:8888/ \
	virt-builder $DEBUG $OS \
	--arch x86_64 \
	--size 10G \
	--format $FORMAT \
	-o $IMG_FN \
	--network \
	--hostname $HOSTNAME \
	--root-password password:'root' \
	--timezone "Asia/Shanghai" \
	--firstboot-command "useradd -s /bin/bash -m -p '' $UM -g sudo; echo $UM:'LeisureLinux' | chpasswd; chage -d0 $UM" \
	--firstboot-command 'dpkg-reconfigure openssh-server' \
	--firstboot-command "sed -i -e 's/ens2/ens3/' /etc/network/interfaces" \
	--firstboot-command "ip link set ens3 up" \
	--firstboot-command "dhclient ens3" \
	--firstboot-command "systemctl --now enable systemd-networkd" \
	--firstboot-command "sed -i -e 's/#NTP=/NTP=ntp.aliyun.com/' /etc/systemd/timesyncd.conf" \
	--firstboot-command "systemctl --now enable systemd-timesyncd" \
	--firstboot-command "localectl set-locale LANG=zh_CN.UTF8" \
	--run-command "locale-gen" \
	--ssh-inject root:file:/home/$UM/.ssh/id_rsa.pub

# --write /etc/apt/sources.list:"$DEB_APT_SRC" \
# --run-command "apt update" \
# --run-command "apt -y install vim psmisc neofetch" \

[ $? != 0 ] && echo "Error: Generate qcow2 failed!" && exit $?

virt-install \
	--memory 4096 \
	--vcpu 2 \
	--name $HOSTNAME \
	--osinfo detect=on,name=generic \
	--network default \
	--import --disk $IMG_FN,bus=sata
