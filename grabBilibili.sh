#!/bin/bash
# 抓取B站自己已经发布的视频的信息：视频标题，视频 BVID，发布时间（timestamp）
# COOKIE 变量是从登录到B站后进入浏览器的开发模式
# 选择：网络->Fetch/XHR->标头->请求标头->cookie 的值
COOKIE="sample_cookie_data;b_ut=-1; i-wanna-go-back=-1; _uuid=3BE; "
RES="bilibili.csv"
cat /dev/null >$RES
# 共抓取13页
for p in $(seq 1 13); do
	URL='https://member.bilibili.com/x/web/archives?status=is_pubing,pubed,not_pubed&pn='$p'&ps=50&coop=1&interactive=1'
	curl -o - -b "$COOKIE" "$URL" | jq .data.arc_audits | jq -r '.[]|.Archive|[.title,.bvid,.ptime]|@csv' >>$RES
done
