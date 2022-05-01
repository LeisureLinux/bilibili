#!/bin/bash
# Author: Bilibili/Github ID: LeisureLinux
# Grab bing.com homepage background as Desktop wallpaper
# Install wallstreet, the wallpaper switch application
# Previously I put it under Pictures folder, not the right way
# DIR=$(xdg-user-dir PICTURES)
DIR=$(systemd-path user-shared 2>/dev/null)
[ -z "$DIR" ] && DIR=$HOME/.local/share
# $XDG_CURRENT_DESKTOP is not in XDG standard
DESKTOP=$(echo "$XDG_DATA_DIRS" | grep -Eo 'xfce|kde|gnome')
[ "$DESKTOP" = "kde" ] && WP_DIR="$DIR/wallpapers" || WP_DIR="$DIR/backgrounds"
UNLIKE_DIR=$WP_DIR/unlike
[ ! -d $UNLIKE_DIR ] && (mkdir -p $UNLIKE_DIR || exit 1)
# If you dislike any images, manually move them to unlike sub-folder
# Remove 10 days old images in unlike folder
find $UNLIKE_DIR -mtime +10 -exec rm {} \;
DOMAIN="www.bing.com"
# Need proxy to pretend as US IP-Address to get all market's image.
# If you don't have proxy, set PROXY to empty string
PROXY="-x socks5://192.168.7.7:2019"
NUMBER=8
[ -n "$PROXY" ] && LIST="en-ca fr-fr zh-cn en-cn fr-fr de-de en-in ja-jp en-gb en-us en-ww" || LIST=zh-cn
for MKT in en-ca fr-fr zh-cn en-cn fr-fr de-de en-in ja-jp en-gb en-us en-ww; do
	URL="https://$DOMAIN/HPImageArchive.aspx?format=js&idx=0&n=$NUMBER&mkt=$MKT"
	IMG_URL=$(curl $PROXY --compressed -sSL "$URL" | jq -r ".images[].url")
	[ -z "$IMG_URL" ] && echo "Error: Get Bing Image URL failed." && exit 1
	echo "Checking market: $MKT ..."
	for item in $(echo $IMG_URL | tr ' ' '\n'); do
		URL="https://$DOMAIN"$item
		FN=$(echo $item | grep -oP 'id=OHR.\K.*(?=&rf)' | awk -F'_' '{print $1}')".jpg"
		[ -z "$FN" ] && echo "Error: Get Bing image URL filename failed." && continue
		[ -f $WP_DIR/$FN -o -f $UNLIKE_DIR/$FN ] && echo "--Warning: Image $FN grabbed." && continue
		curl -sSL -o $WP_DIR/$FN $URL
		[ $? != 0 ] && echo "Error: Grab $IMG_URL failed." && continue
		echo "**Info: Successfully grabbed image: $FN"
	done
done
