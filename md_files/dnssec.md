#### DNSSEC 杂谈
  - [中国的公共 DNS 服务器](https://public-dns.info/nameserver/cn.html): 上海电信的节点 202.46.34.76 支持 DNSSEC
  - DNSSEC 的作用：签名和校验。
    - DNS 服务器开启 DNSSEC 功能
    - DNS Zone 的管理员用 DNSSEC 的 DNSKEY 对 DNS 记录签名
    - 域名服务提供商会生成一条 DS (Delegation Signer) 记录提供给父 zone(一般而言就是顶级域名TLD)来完成 “global chain of trust”
    - SHOW ME THE CODE:
```
#!/bin/sh
ZONE=leisure.linux
KEY_DIR=$ZONE
# 
ZONE_FILE=$ZONE.zone
DS_FILE=/var/lib/unbound/$ZONE.ds.key
# OUTPUT_FILE=$ZONE.signed
# PRIVATE_KEY_FILE=$(ls $KEY_DIR/*.private 2>/dev/null)
#
# 
gen_key () {
  # 第一步：生成密钥对，到 KEY_DIR
  rm $KEY_DIR/* 2>/dev/null
  # -f KSK
  dnssec-keygen -n ZONE -v 9 -a RSASHA512 -b 2048 -K $KEY_DIR $ZONE
  KEY_FILE=$(ls -1 $KEY_DIR/*.key|tail -1 2>/dev/null)
  rm $ZONE.key 2>/dev/null
  ln -s $KEY_FILE ./$ZONE.key
  # cat $KEY_FILE >> $ZONE_FILE
  # 第二步：根据公钥生成 DS(Deligation Signer) 记录
  rm $DS_FILE 2>/dev/null
  [ -f "$KEY_FILE" ] && dnssec-dsfromkey  $KEY_FILE |sudo -u unbound tee $DS_FILE
  unbound-control reload $ZONE
}

sign () {
  [  -r "$ZONE_FILE.signed" ] && rm $ZONE_FILE.signed
  dnssec-signzone -S -o $ZONE -K $KEY_DIR -z $ZONE_FILE
  [ $? = 0 ] && echo "Info: Signed zone file as: $ZONE_FILE.signed"
}

# Main Prog.
gen_key
sign
```
