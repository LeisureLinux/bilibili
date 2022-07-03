#!/bin/sh
###################################################
# 克隆 multipass 的 Ubuntu 虚拟机                 #
# Clone multipass VMs since virt-clone won't work #
# Bilibili Video:                                 #
# https://www.bilibili.com/video/BV1ZF41137NT/    #
# Author: Bilibili ID: LeisureLinux               #
# Place: Pudong, Shanghai                         #
# Modified: 2022-04-05, Qingming Festival         #
###################################################
orig=$1
new=$2
[ -z "$new" ] && echo "Syntax: $0 orig_domain new_domain" && exit 0
img_json="/var/snap/multipass/common/data/multipassd/vault/multipassd-instance-image-records.json"
release=$(jq -r ".\"$orig\".\"query\".\"release\"" $img_json)
[ -z "$release" -o "$release" = "null" ] && echo "Error: Failed to get original $orig release info" && exit 1
# Get pool path, though no need any more.
# new_path=$(virsh pool-dumpxml $orig | egrep -v 'uuid|capacity unit=|allocation unit=|available unit=' | sed -e "s/$orig/$new/g" | xmllint --xpath "string(//path)" -)
# Don't use virt-clone, it wil create a storage pool for every cloned VM
# sudo virt-clone -m RANDOM -o $orig -n $new --auto-clone
# 1. 用 multipass 创建一个小的虚拟机，-d 硬盘尺寸可以小一点
echo "Info: 正在用 multipass 创建虚拟机： $new ..."
multipass launch $release -m 2g -c 1 -d 4G --name $new
[ $? != 0 ] && echo "Error: Failed to launch new domain: $new" && exit 2
multipass stop $new
# 把旧的虚机也要停掉
multipass stop $orig 2>/dev/null
sleep 4
# 2. 获取新旧虚拟机的磁盘完整文件名(带路径)，把旧文件覆盖到新虚拟机的文件。
orig_img=$(sudo virsh -q domblklist ${orig} | grep vda | awk '{print $NF}')
new_img=$(sudo virsh -q domblklist ${new} | grep vda | awk '{print $NF}')
[ -z "$orig_img" -o -z "$new_img" ] && echo "Error: Failed to get disk images" && exit 3
sudo cp $orig_img $new_img
# 3. 清理新建虚拟机内的"克隆"过来的信息
echo "Info: 初始化新克隆的虚拟机 $new ..."
sudo virt-sysprep -d $new --enable customize --network \
	--timezone Asia/Shanghai --update --keep-user-accounts ubuntu \
	--operations=net-hwaddr,machine-id,tmp-files,utmp,dhcp-client-state
# 4. 重启 multipassd 服务
echo "Info: 重启 multipassd 服务 ..."
sudo snap restart multipass.multipassd
sleep 10
