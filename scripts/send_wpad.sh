#!/bin/sh
# Send exported SwitchyOmega pac file to remote wpad web server.
# move the latest exported pac file as wpad.dat
# Bilibili Video: https://www.bilibili.com/video/BV1eu4y1A7DX/
# 相关视频：
#  - https://www.bilibili.com/video/BV1V14y1M72V/
#  - https://www.bilibili.com/video/BV12B4y1X7k7/
#  - https://www.bilibili.com/video/BV1WF411i7vz/
# 把浏览器的 SwitchyOmega 插件的自动切换+gfwlist 的 pac 文件导出后修改为 wpad.dat 文件后，发送到 wpad 服务器
# wpad 可以实现内网设备只要配置为自动代理，就能同步接收到http://wpad/wpad.dat 这个 pac 脚本，
# 无需其他任何的特殊配置或者安装其他任何客户端，实现通过内网的代理进行科学的上网
# 脚本主要解决了多次导出文件名包含空格的问题，对 find 结果排序取最新的那个文件改名
# By Bilibili ID: @LeisureLinux
# 最后修改日期：2023年 11月 19日 星期日 16:06:57 CST
#
# SwitchyOmega 只能配置一个代理，默认选择 HTTP 代理协议，为了提高可靠性，修改 wpad 脚本，增加 SOCKS5 配置
OLD="wpad:8888"
NEW="wpad:8888; SOCKS5 wpad:2023"
# 以上两个变量需要根据SwitchyOmega 的配置以及自己是否有 SOCKS5 代理来决定
# 如果不修改 OLD & NEW 变量，下面的 sed 语句应该不会生效，因此不会影响结果
PFILE="auto_switch" # Profile name
PAC=$(find "$HOME"/Downloads -name "OmegaProfile_*.pac" -print0 2>/dev/null | xargs -r -0 ls -t | head -1)
[ -z "$PAC" ] && echo "Info: No exported pac file found." && exit
echo "Info: Found latest PAC File: $PAC"
fn="$HOME/Downloads/OmegaProfile_$PFILE.pac"
[ "$PAC" != "$fn" ] && mv "$PAC" "$fn" && echo "Info: moved pac file $PAC to $fn"
# [ ! -f "$fn" ] && echo "Info: No exported pac file found." && exit
WPAD_DIR="$HOME/.config/pac"
[ ! -d "$WPAD_DIR" ] && mkdir -p "$WPAD_DIR"
WPAD="$WPAD_DIR/wpad.dat"
mv "$fn" "$WPAD" && echo "Info: moved $fn to $WPAD"
# Remove any existing pac files
find "$HOME"/Downloads -name "OmegaProfile_*.pac" -print0 2>/dev/null | xargs -r -0 rm
# 替换 Proxy 配置
sed -i -e "s/$OLD/$NEW/g" "$WPAD"

# 每天用 genpac 生成 wpad 格式支持的 gfwlist（从网络下载并转换），供有需要者使用
# X=$(($(date +"%s") - $(stat -c "%Y" "$WPAD")))
# if [ "$X" -gt 86400 ]; then
# 	/usr/local/bin/genpac --format=pac --pac-proxy="PROXY wpad:8888; SOCKS5 wpad:2023" --gfwlist-proxy "SOCKS5 wpad:2023" | tee "$WPAD" >/dev/null
# fi
test_pac() {
	if [ "$1" = "remote" ]; then
		WPAD=/tmp/wpad.dat
		curl -sSf http://wpad/wpad.dat -o "$WPAD"
	fi
	for u in https://bbc.co.uk https://zh.annas-archive.org/ http://www.sina.cn; do
		(
			echo "Verify $u: "
			pactester -p "$WPAD" -u $u
		) | xargs
	done
}

# Main Prog.
#
test_pac
# put username@hostname in your ~/.ssh/config file, so to mask the username in this script
if scp -q "$WPAD" wpad:/var/www/html/wpad; then
	echo "Successfully send new wpad.dat to wpad host"
	test_pac remote
	# Todo: reload remote Nginx
else
	echo "Error: Failed to send new wpad.dat to wpad host"
fi
