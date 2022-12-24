#!/bin/sh
#
# virt-builder --list 显示支持的 OS，大多数 Fedora，Debian，CentOS，都支持
# Ubuntu 的 LTS 版本
# root 密码为 root，当前用户的公钥可以直接 ssh root@虚机 IP
# 当前用户密码为 LeisureLinux，首次登录时会要求修改密码
# Bug 01: 网卡不一定是 ens3
# Bug 02: 缺少 sudo 包
#

OS="$1"
HOSTNAME="$1-99"
# 当前用户名作为镜像内的用户名
UM="$USER"
# 镜像格式：qcow2 or raw
FORMAT="qcow2"
# 镜像文件名
IMG_FN="$HOSTNAME.$FORMAT"

DEB_APT_SRC=""

# Set DEBUG="-v" if needed
# export LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1
DEBUG="-v"
#
# proxy server
time sudo all_proxy=http://internal-proxy:8080/ \
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
