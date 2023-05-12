#!/bin/sh
# 使用 edid-decode 读取显示器序列号，型号，品牌名称，出厂日期(周)，厂商名称
# Last modified: Fri May 12 20:20:21 CST 2023
# Comment in "HIDE" to show product serial number in output
HIDE="--hide-serial-numbers"
for m in $(ls /sys/class/drm/*/edid); do
	dev=$(basename $(dirname $m))
	edid=$(edid-decode -c $HIDE $m 2>/dev/null | grep -E \
		"Manufacturer:|Model:|Made in:|Product Serial Number:|Product Name:" | paste \
		-d "," - - - - - | sed -e 's/,  */,/g' -e 's/Product //g' -e 's/^[ \t]*//')
	[ -n "$edid" ] && echo "Device Name:$dev,$edid"
done
