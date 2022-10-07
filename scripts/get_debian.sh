#!/bin/bash
# set -x
# Check and install Debian's latest package onto Ubuntu
# Compare local version and remote version
# Use gdebi(install gdebi-core first) to install newer version if needed
# Author Bilibili ID: LeisureLinux
# Ver: 1.3.20221007
PKG=$1
[ -z "$PKG" ] && echo "Syntax: $0 pkg_name" && exit 2
# Debian mirror site: https://packages.debian.org/sid/
SITE_URL="http://ftp.cn.debian.org/debian/"
DEB_RELEASE="sid"
ARCH=$(dpkg --print-architecture)
PKG_IDX=${SITE_URL}"dists/${DEB_RELEASE}/main/binary-${ARCH}/Packages.xz"

# Main Prog.
L_VER_FULL=$(dpkg-query -W $PKG ${Version} 2>/dev/null | awk '{print $2}')
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
