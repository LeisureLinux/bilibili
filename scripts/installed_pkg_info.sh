#!/bin/sh
############################################################
# 查看 Debian/Ubuntu 操作系统内已经安装的所有软件包的信息
# List installed package info
# 不包含/Exclude:
# 1. ^lib
# 2. -dev$
# 3. ^fonts-
# 4. ^python3-
# 5. :
# Author: Bilibili ID: LeisureLinux
# Video: https://www.bilibili.com/video/BV1w44y1V79V/
# Modified: 2022-04-05 in Pudong, Shanghai
############################################################

for p in $(dpkg-query -W | awk '{print $1}' | egrep -v '^lib|^fonts-|^python3-|-dev$|:'); do
	echo "Package: $p ..."
	apt-cache show $p | grep ^Description | grep -v md5
	BIN=$(dpkg -L $p | egrep '/bin/|/sbin/' | xargs)
	[ -n "$BIN" ] && echo "Bin-files: $BIN"
	echo "============================================="
done
