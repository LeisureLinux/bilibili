#!/bin/sh
# 把 B站抓取到的 csv 文件，转换成每个月一个 Markdown 文件
# 输出的 Markdown 文件名类似： 202108.md
RES="bilibili.csv"
PREFIX="https://www.bilibili.com/video/"
# Sample CSV Line: "免费的 Chrome 浏览器录屏插件 Screenity 介绍","BV1yU4y157HY",1623671382
# Sample Markdown Line:
#     - [免费的 Chrome 浏览器录屏插件 Screenity 介绍](https://www.bilibili.com/video/BV1yU4y157HY)
for M in $(seq -f "%02g" 5 11); do
	OUTPUT="2021$M.md"
	echo "- 2021$M" >$OUTPUT
	awk -v M=$M -v P=$PREFIX -F, 'strftime("%Y%m",$3) == "2021" M {print "    - [" $1 "](" P $2 ")" }' $RES | sed -e 's#"##g' >>$OUTPUT
done
