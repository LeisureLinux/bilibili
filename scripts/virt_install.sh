#!/bin/bash
# Author's Bilibili ID: LeisureLinux
# Auto download cloud image from Internet, used as base, resize to 10G, launch different VMs
# Similar Ubuntu multipass command:
# multipass launch mp_img_name -n domain_name -c 2 -m 4g -d 10g --cloud-init demo.yaml
# Once script run completed, run virsh console $NAME to check the cloud-init status
# Exit console, run ssh DEFAULT_USER@IP to verify the pub key is injected correctly
# Todo:
# 1. Support parameter pass in
# 2. Place downloaded image into a permenent dir
# 3. modify CL_INIT based on image, add mirror support, change default cloud-user
# 4. add opencloudOS
# 5. check why openeuler failed
# How to troubleshoot:
# In case no network or something else wrong, reset root password:
#   $ virsh destroy VM
#   $ sudo virt-customize -d VM-NAME --root-password password:ROOT-PASS
# ============================================================================
# VM Name
NAME=$1
# IMG can be local path for iso/qcow2, can also be OS-Type(see supported_os)
IMG=$2
# 2c/4GB/10GB as default
CPU=2
MEM=4096
DISK_SIZE=$3
[ -z "$DISK_SIZE" ] && DISK_SIZE=10
[ -z "$IMG" ] && echo "Syntax: $0 vm_name image_file [size] or $0 vm_name vm_type/img_url" && exit 0
# Cloud Image dir, Do not place "-" in dir name
BASE_DIR="/nfsroot/iso/cloud"
# Output VM Dir
VM_DIR="/nfsroot/VMs/cloud"
# Your own key file to load
PUB_KEY="/home/$USER/.ssh/id_rsa.pub"
# Temporary cloud-init.yaml file
CL_INIT="/tmp/$(basename $0 .sh).yaml"
[ ! -x /usr/bin/axel ] && echo "Error: Please install axel package" && exit

supported_os() {
	# ============================================================================
	# local OS=$1
	# NJU and SJTU mirror to download cloud images
	NJU="https://mirrors.nju.edu.cn"
	SJTU="https://mirrors.sjtug.sjtu.edu.cn"
	# cloud urls
	# test passed
	local fedora=$NJU"/fedora/releases/38/Cloud/x86_64/images/Fedora-Cloud-Base-38-1.6.x86_64.raw.xz"
	local almalinux=$NJU"/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
	local jammy=$NJU"/ubuntu-cloud-images/jammy/current/jammy-server-cloudimg-amd64.img"
	local rocky=$SJTU"/rocky/9.1/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2"
	local arch=$NJU"/archlinux/images/latest/Arch-Linux-x86_64-cloudimg.qcow2"
	# username is cloud-user, not centos
	local centos=$NJU"/centos-cloud/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-20230501.0.x86_64.qcow2"
	# need to find a proper CN mirror for debian
	# local debian="https://cdimage.debian.org/cdimage/cloud/bookworm/daily/latest/debian-12-generic-arm64-daily.qcow2"
	local debian="https://cdimage.debian.org/cdimage/cloud/bookworm/daily/latest/debian-12-generic-amd64-daily.qcow2"
	# Failed test:
	local openeuler=$NJU"/openeuler/openEuler-23.03/virtual_machine_img/x86_64/openEuler-23.03-x86_64.qcow2.xz"
	#
	[ -n "${!IMG}" ] && URL=${!IMG} && return
	echo "Error: Supported-OS: arch,almalinux,centos,debian,fedora,jammy,openeuler,rocky"
	echo "Syntax: $0 VM-NAME Supported-OS"
	exit 1
}
# ============================================================================
# Normally you don't need to change code below
# Though function gen_yaml need to elaborate based on different OS_Type
#
[ ! -r $PUB_KEY ] && echo "Error: $PUB_KEY not found." && exit 1
#
[ ! -d $BASE_DIR ] && mkdir -p $BASE_DIR
[ ! -d $VM_DIR ] && mkdir -p $VM_DIR

net_install() {
	# Debian URL: e.g IMG=https://mirror.nju.edu.cn/debian/dists/stable/main/installer-amd64/
	# Fedora URL: https://mirror.nju.edu.cn/fedora/releases/38/Server/x86_64/os/
	sudo virt-install \
		--connect qemu:///system \
		--graphics vnc \
		--vcpu $CPU \
		--memory $MEM \
		--name $NAME \
		--network default \
		--disk size=$DISK_SIZE \
		--osinfo detect=on,name=generic \
		--location $IMG
}

gen_yaml() {
	# Part A
	cat >$CL_INIT <<EOA
#cloud-config
# vim: syntax=yaml
#

users:
  - default

# Set timezone
timezone: "Asia/Shanghai"
ntp:
  ntp_client: "systemd-timesyncd"
  servers:
    - ntp.aliyun.com
  enabled: true
#
manage_etc_hosts: true
locale: "zh_CN.UTF-8"
disable_root: false
local-hostname: $NAME
ssh_authorized_keys:
EOA
	# Add pub key
	echo "  - $(cat $PUB_KEY)" >>$CL_INIT
	# Part B
	# - language-pack-zh-hans-base
	# - language-pack-zh-hans
	# byobu_by_default: disable-system
	cat >>$CL_INIT <<EOB
package_update: false
package_upgrade: false
package_reboot_if_required: false
packages:
  - network-manager
  - avahi-daemon
  - qemu-guest-agent
  - neofetch
  - neovim
byobu_by_default: enable-user
write_files:
  - content: |
      # Welcome To LeisureLinux
      alias update='sudo apt update && sudo apt upgrade && sudo apt dist-upgrade && sudo apt autoremove && sudo apt auto-clean'
    path: /etc/skel/.bashrc
    append: true
  - content: |
      printf "\n"
      printf " * Github:  https://github.com/LeisureLinux\n"
      printf " * Bilibili: https://space.bilibili.com/517298151\n"
      printf "\n"
    path: /etc/update-motd.d/10-help-text
runcmd:
  - apt purge -y snapd
  - chmod -x /etc/update-motd.d/[5-9]*
  - systemctl --now disable multipathd
  - systemctl --now disable ModemManager
  - systemctl --now disable ubuntu-advantage

EOB

	# Final part
	cat >>$CL_INIT <<EOF
final_message: "The system is finally up, after \$UPTIME seconds"
EOF
}

iso() {
	/usr/bin/virt-install -d \
		--vcpu $CPU \
		--memory $MEM \
		--name $NAME \
		--disk size=$DISK_SIZE \
		--osinfo detect=on,name=generic \
		--network default \
		--cdrom $IMG
}

cloud() {
	# Todo: check the image date, if 30 days old, still download
	shopt -s nullglob
	BASE=$(ls $BASE_DIR/*.qcow2 $BASE_DIR/*.img $BASE_DIR/*.raw | grep -i ^$BASE_DIR/$IMG | tail -1)
	# echo "base:$BASE Img:$IMG"
	# If image not exist
	if [ -n "$BASE" ]; then
		echo "Info: Base image $BASE found."
	else
		supported_os $IMG
		echo "Info: Downloading cloud-image from ${URL} to $BASE_DIR"
		axel ${URL} -o $BASE_DIR
		[ $? != 0 ] && echo "Error: failed to download ${URL}" && exit 5
		BASE=$BASE_DIR/$(basename $URL)
	fi
	# [ -z "$BASE" ] && echo "Error: No Image found for $IMG under $BASE_DIR" && exit 6
	# Decompress xz file
	[ "$(basename $BASE .xz)" != "$(basename $BASE)" ] && xz -v -d $BASE && BASE=$BASE_DIR/$(basename $BASE .xz)
	FORMAT=$(qemu-img info --output json $BASE | jq -r .format)
	[ $? != 0 ] && echo "Error: Wrong format detected for $BASE" && exit 7
	# the Output VM Disk File Name
	DISK=$VM_DIR/$NAME.$FORMAT
	#
	# sudo qemu-img resize $DISK ${DISK_SIZE}G
	sudo qemu-img create -b $BASE -F $FORMAT -f qcow2 $DISK ${DISK_SIZE}G
	install
}

install() {
	sudo virt-install \
		--vcpu $CPU \
		--memory $MEM \
		--name $NAME \
		--osinfo detect=on,name=generic \
		--network default \
		--noautoconsole \
		--import --disk $DISK,bus=virtio \
		--cloud-init user-data=$CL_INIT
	# --cloud-init root-password-generate=on,disable=on,ssh-key=/home/xxx/.ssh/id_rsa.pub
	# clouduser-ssh-key=$PUB_KEY,root-ssh-key=$PUB_KEY
	# network-config
}

# Main Prog.
if [ "$(echo $IMG | cut -c1-4)" = "http" ]; then
	net_install
	exit 0
fi
if [ "$(basename $IMG .iso).iso" = "$(basename $IMG)" ]; then
	echo "Install from Live CD: $IMG"
	iso
else
	echo "Import qcow2 disk: $IMG"
	[ -r $IMG ] && DISK=$IMG
	[ -r $BASE_DIR/$IMG ] && DISK=$BASE_DIR/$IMG
	gen_yaml
	[ -n "$DISK" ] && install || cloud
fi
