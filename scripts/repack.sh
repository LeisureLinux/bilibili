#!/bin/sh
# download, extract, edit pkg metainfo, then repack binary package
# Syntax: $0 pkg_name[=version] to download & extract
#  After modify, run: $0 -p pkg_name to repack
[ "$1" = "-p" ] && PKG=$2 || PKG=$1
# PKG take the form: pkgname=version
DIR=$(echo $PKG | awk -F= '{print $1}')
[ -z "$DIR" ] && echo "Error: wrong package name: $PKG" && exit 1

[ "$1" != "-p" -a -d "$DIR" ] && echo "Error: $DIR existed, please remove it first" && exit 2
[ "$1" != "-p" ] && mkdir -p $DIR
# Make it an absolute dir
DIR=$PWD/$DIR

pkg_download() {
	# 下载二进制包，或者是从别的地方下载下来的 .deb 二进制包
	cd $DIR
	apt download $PKG
	[ $? != 0 ] && echo "Error: unable to find package $PKG!" && exit 1
	DEB=$(basename $DIR/*.deb)
}

pkg_extract() {
	cd $DIR
	# 解开二进制包以及控制文件
	dpkg-deb -R $DEB .
	rm $DEB
	# 修改 DEBIAN/control(version字段)文件以及 changelog 等其他需要修改的文件
	# 修改 changelog, 以 nginx 包为例子
	mkdir debian
	CHLOG=$(find . -name "changelog.Debian.gz")
	zcat $CHLOG >debian/changelog
	echo " -- Now you can cd $DIR, modify DEBIAN/control file "
	echo "    Also run like \"debchange -D unstable -l ubuntu\" to modify changelog if needed."
	echo " -- then run $0 -p $PKG to repack"
}

pkg_repack() {
	# 重新打包
	cd $DIR 2>/dev/null
	[ $? != 0 ] && echo "Error: $DIR not exist!" && exit 11
	# 如果修改了 changelog，以 nginx 包为例子
	CHLOG=$(find . -name "changelog.Debian.gz")
	[ -f "debian/changelog" -a -f "$CHLOG" ] && gzip -9 -c debian/changelog >$CHLOG && rm -rf debian
	# 打包
	[ ! -f "DEBIAN/control" ] && echo "Warn: no control file found, no need to repack!" && exit 12
	DEBNAME=$(grep -E '^Package|^Version|^Architecture' DEBIAN/control | awk '{print $2}' | xargs | sed -e 's/ /_/g')
	fakeroot dpkg-deb -b . ../${DEBNAME}.deb
	[ $? != 0 ] && echo "Error: repack failed!" && exit 13
}

# Main Prog.
if [ "$1" = "-p" ]; then
	pkg_repack
else
	pkg_download
	pkg_extract
fi
