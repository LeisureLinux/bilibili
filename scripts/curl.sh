#!/bin/bash
WPAD_URL="http://192.168.7.11/wpad.dat"
P=$(curl -sS $WPAD_URL | pactester -p - -u "${@: -1}" | awk -F';' '{print $1}' | awk '{print $NF}')
[ $P = "DIRECT" ] && P="" || P="-x http://$P"
# Return as: PROXY 192.168.7.11:8888; HTTP 192.168.7.11:8888; HTTPS 192.168.7.11:8888; SOCKS5 192.168.7.11:2019
echo "proxy: $P"
/usr/bin/curl $P $@
