#!/bin/bash
# set -x
# Check and install Debian's latest package onto Ubuntu
# The purpose is to check and auto-upgrade current installed Debian Pkgs
# Compare local version and remote version
# Use gdebi(install gdebi-core first) to install newer version if needed
# Author Bilibili ID: LeisureLinux
# Ver: 2.0.20221007
#######################################################################
# How to instal Debian sid packages onto Ubuntu with update still available
# * Below script still have some value for those don't like to touch /etc/apt/*
# * The New way to install and update the Debian packages onto Ubuntu is use Pin Priority
# * $ cat /etc/apt/sources.list.d/debian.list
# deb http://ftp.cn.debian.org/debian sid main
# * $ cat /etc/apt/preferences.d/debian
# # Never prefer packages from debian
# Package: *
# Pin: origin *.debian.org
# Pin-Priority: 1
#
# # Allow upgrading only chromium from debian
# Package: chromium
# Pin: origin *.debian.org
# Pin-Priority: 500
#
# * Install keyring: $ sudo apt install debian-archive-keyring
# * $ sudo apt update && sudo apt -t sid install chromium
#######################################################################
PKG=$1
[ -z "$PKG" ] && echo "Syntax: $0 pkg_name" && exit 2
# Debian mirror site: https://packages.debian.org/sid/
SITE_URL="http://ftp.cn.debian.org/debian/"
DEB_RELEASE="sid"
ARCH=$(dpkg --print-architecture)
PKG_IDX=${SITE_URL}"dists/${DEB_RELEASE}/main/binary-${ARCH}/Packages.xz"

# Main Prog.
L_VER_FULL=$(dpkg-query -f='${Version}' -W $PKG 2>/dev/null)
L_VER=$(echo $L_VER_FULL | cut -d'-' -f 1)
# Todo: Check Depends
read -r R_VER_FULL URI <<<$(curl -sSL -o - $PKG_IDX | xzcat | sed -n "/^Package: ${PKG}$/,/^$/p" | grep -E "^Version:|^Filename:" | xargs | awk '{print $2,$4}')
R_VER=$(echo $R_VER_FULL | cut -d'-' -f 1)
[ -z "$R_VER" ] && echo "Error: Unable to get remote $PKG version number." && exit 2
#
# echo "Local Version: $L_VER, Remote Version: $R_VER"
[ "$L_VER" = "$R_VER" ] && echo "Info: No need to upgrade" && exit 0
FN=$(basename $URI)
URL=${SITE_URL}${URI}
curl -sSL -o /tmp/$FN $URL
[ $? != 0 ] && echo "Error: Download $URL failed!" && exit 5
echo "Info: Package downloaded as /tmp/$FN from $URL"
# sudo dpkg -r $PKG
# [ $? != 0 ] && echo "Error: failed to remove $PKG!" && exit 6
sudo gdebi /tmp/$FN
[ $? != 0 ] && echo "Error: Install $PKG failed!" && exit 9
echo "$PKG installed successfully." && rm /tmp/$FN
