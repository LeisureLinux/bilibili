#!/bin/bash
# Generate Markdown Files
# Kudos to: https://www.starkandwayne.com/blog/bash-for-loop-over-json-array-using-jq/
# For each video we will generate markdown lines into N TAGS.md files and one YYYYmm.md file

PREFIX="https://www.bilibili.com/video/"
markmap="node $HOME/node_modules/markmap-cli/bin/cli.js --no-open"

genVideo() {
	local VIDEO_FILE=$1
	[ -s "$VIDEO_FILE" ] && return
	echo "- " >>$VIDEO_FILE
	echo "    - [$TITLE]($PREFIX$BVID)
        - 时长：$DURATION 秒
        - 日期：[$PTIME](../$HTML_MON)
        - 标签：$TAGS
        - [封面]($COVER)" >>$VIDEO_FILE
	if [ -n "$DESC" ]; then
		# Put 8 space and add a new line
		echo "        - 简介：
            > \"$DESC\"" >>$VIDEO_FILE
		echo >>$VIDEO_FILE
	fi
}

genMarkmap() {
	#Generate Markmap HTML
	echo "Info: 生成 Markmap HTML 文件 ..."
	MD_INDEX="README.md"
	echo "## [LeisureLinux B站视频笔记](https://space.bilibili.com/517298151)
-" >$MD_INDEX
	cat temp/*.md >>$MD_INDEX
	# rm temp/*.md
	#for f in tags/*.md; do
	#b=$(basename $f .md)
	#$markmap $f -o markmap/$b.html
	#echo "- [$b](markmap/$b.html)" >>$MD_INDEX
	#done
	# Will manually generate the homepage
	# Todo: add bymonth.md here
	$markmap $MD_INDEX -o index.html
}

# Main Prog.
for row in $(cat "bilibili.json" | jq -r '.|@base64'); do
	_jq() {
		echo ${row} | base64 --decode | jq -r ${1}
	}
	TITLE=$(_jq '.title')
	BVID=$(_jq '.bvid')
	COVER=$(_jq '.cover')
	DURATION=$(_jq '.duration')
	DESC=$(_jq '.desc')
	DESC=$(echo "$DESC" | tr '\n' '  ')
	PTIME=$(_jq '.ptime')
	# Make the output file as month/<YYYYMM>.md
	# 文件名不要有短划线
	MON=$(echo $PTIME | cut -d '-' -f1,2 | sed 's#-##g')
	# MON=$(echo $PTIME | cut -d '-' --output-delimiter='' -f1,2 2>/dev/null)
	# MD_MON="month/${MON}.md"
	# HTML_MON="markmap/${MON}.html"
	# [ ! -s "$MD_MON" ] && echo "- $MONDASH" >$MD_MON
	TAGS=$(_jq '.tag')
	# 全部转换成小写，避免大小写混合产生不同的文件名
	TAGS=$(echo $TAGS | tr '[A-Z]' '[a-z]')
	# FIRST_TAG=$(echo $TAGS | cut -d',' -f1)
	# MD_FIRST="tags/${FIRST_TAG}.md"
	# HTML_FIRST="markmap/${FIRST_TAG}.html"
	# ####
	# Process Other Tags
	# OTHER_TAGS=""
	genVideo "videos/$BVID.md"
	for t in $(echo $TAGS | sed 's#,#\n#g'); do
		MD_TAG="temp/${t}.md"
		# HTML_TAG="markmap/${t}.html"
		# [ ! -s "$MD_TAG" ] && echo "- $t ([返回上层](../))" >$MD_TAG
		[ ! -s "$MD_TAG" ] && echo "- <a name="$t"></a>$t" >$MD_TAG
		# [$t](#$t)"

		#if [ "$t" == "$FIRST_TAG" ]; then
		#continue
		#fi
		# OTHER_TAGS="$OTHER_TAGS[$t](../$HTML_TAG),"
		# if this video already in the tag md file then skip
		#if [ -n "$(grep $BVID $MD_TAG 2>/dev/null)" ]; then
		#continue
		#fi
		# echo "    - [$TITLE]($PREFIX$BVID)"
		echo "    - [$TITLE](videos/$BVID.html)" >>$MD_TAG
		echo >>$MD_TAG
		# addDesc $MD_TAG
	done
	# Process First Tag
	#[ ! -s "$MD_FIRST" ] && echo "- $FIRST_TAG" >$MD_FIRST
	#echo "
	#- **[$TITLE]($PREFIX$BVID)**
	#- 时长：$DURATION 秒
	#- 日期：[$PTIME](../$HTML_MON)
	#- 其他标签：$OTHER_TAGS
	#- [封面]($COVER)" >>$MD_FIRST
	#addDesc $MD_FIRST
	## Process Month Markdown File
	#echo "
	#- [$TITLE]($PREFIX$BVID)
	#- 去主标签查看笔记/注释：[$FIRST_TAG](../$HTML_FIRST)
	#- 时长：$DURATION 秒
	#- 日期：$PTIME
	#- 副标签：$TAGS
	#- [封面]($COVER)" >>$MD_MON
	#addDesc $MD_MON
done
#
MD_INDEX="README.md"
echo "## [LeisureLinux B站视频笔记](https://space.bilibili.com/517298151)
-" >$MD_INDEX
cat temp/*.md >>$MD_INDEX
rm -f temp/*.md 2>/dev/null
# genMarkmap

#git add tags/*.md
#git add markmap/*.html
#git commit -a -m "$(date +\"%Y-%m-%d\")"
#git push
