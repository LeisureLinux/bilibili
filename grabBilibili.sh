#!/bin/bash
# 抓取B站自己已经发布的视频的信息：视频标题，视频 BVID，发布时间（timestamp）
# COOKIE 变量是从登录到B站后进入浏览器的开发模式
# 选择：网络->Fetch/XHR->标头->请求标头->cookie 的值
[ -z "$1" ] && echo "Syntax: $0 \"\$COOKIE\" " && exit 1
COOKIE="$1"
RES="bilibili.json"
bArch='https://member.bilibili.com/x/web/archives?status=pubed&ps=10&coop=1&interactive=1&pn='

grabHistory() {
	# 抓取历史存量
	# 共抓取13页
	cat /dev/null >$RES
	for p in $(seq 1 13); do
		URL=${bArch}$p
		curl -s -o - -b "$COOKIE" "$URL" | jq .data.arc_audits | jq -r '.[]|.Archive|[.title,.bvid,.ptime]|@csv' >>$RES
	done
}

grabFirstPage() {
	URL=${bArch}1
	# curl -s -o - -b "$COOKIE" "$URL" | jq .data.arc_audits | jq -r '.[]|.Archive|[.title,.bvid,.ptime]|@csv' >$RES
	curl -s -o - -b "$COOKIE" "$URL" | jq .data.arc_audits | jq '.[]|.Archive' | jq '.ptime |= strflocaltime("%Y-%m-%d")' | jq '{bvid,title,cover,tag,duration,desc,ptime}' >$RES
}

# Main.
grabFirstPage
