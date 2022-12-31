#!/bin/sh
# Generate ADBlock list from different source in unbound local-zone format with "always_null"
#
ZONE_DIR=/etc/unbound/adblock
mkdir -p $ZONE_DIR
PROXY="--proxy socks5h://localhost:2023"
ZONE_FILE=$ZONE_DIR/noad.conf
TMP_FILE=/tmp/noad.conf.tmp

block() {
  AD_URL=$1
  echo "Info: Grabbing $AD_URL ..."
  # Old syntax not using always_null, need two lines
  # curl $PROXY -sSL $AD_URL| grep '^0\.0\.0\.0' | awk '{print "local-zone: \""$2"\" redirect\nlocal-data: \""$2" A 0.0.0.0\""}' >> $TMP_FILE
  curl $PROXY -sSL $AD_URL | grep '^0\.0\.0\.0' | awk '{print "local-zone: \""$2"\" always_null\n"}' | grep . >>$TMP_FILE
}

AD_URL="https://unbound.oisd.nl/"
echo "Info: Grabbing $AD_URL ..."
curl $PROXY -sSL $AD_URL -o $TMP_FILE
# nsfwbig is a big list as well, maybe too big
# curl $PROXY -sSL $AD_URL -o oisd.nsfwbig.conf

block "https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts"
block "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social/hosts"
block "https://blocklistproject.github.io/Lists/adobe.txt"
# This everything.txt maybe too big, just put as comment here
# block "https://blocklistproject.github.io/Lists/everything.txt"
# Sort
grep -v "0.0.0.0" $TMP_FILE | sort | uniq >$ZONE_FILE.new
rm $TMP_FILE
if [ "$(cat $ZONE_FILE | md5sum)" = "$(cat $ZONE_FILE.new | md5sum)" ]; then
  echo "Info: Zonefile not changed, do nothing"
else
  mv $ZONE_FILE.new $ZONE_FILE
  unbound-control reload
  echo "Info: Blocked $(grep "^local-zone" $ZONE_FILE | wc -l) domains"
fi
