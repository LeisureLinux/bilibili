#### 内网启用 DNSSEC 
  - [中国的公共 DNS 服务器](https://public-dns.info/nameserver/cn.html): 上海电信的节点 202.46.34.76 支持 DNSSEC
  - DNSSEC 的作用:“签名和校验”。
    - DNS 服务器开启 DNSSEC 功能
    - DNS Zone 的管理员用 DNSSEC 的 DNSKEY 对 DNS 记录签名
    - 域名服务提供商会生成一条 DS (Delegation Signer) 记录提供给父 zone(一般而言就是顶级域名TLD)来完成 “global chain of trust”
    - Refer: 
      1. [A Minimum Complete Tutorial of DNSSEC](https://metebalci.com/blog/a-minimum-complete-tutorial-of-dnssec/)
      2. [Decreasing Access Time to Root Servers by Running One on Loopback](https://www.rfc-editor.org/rfc/rfc7706)
      3. [Evaluating Local DNSSEC Validators](https://www.redpill-linpro.com/techblog/2019/08/27/evaluating-local-dnssec-validators.html#unbounddnssec-trigger)
    - SHOW ME THE CODE:
```
  #!/bin/sh
  ZONE=$1
  [ -z "$ZONE" ] && echo "Syntax: $0 zonename" && exit 0
  KEY_DIR=$ZONE
  [ ! -d "$KEY_DIR" ] && mkdir $KEY_DIR
  # 
  ZONE_FILE=$ZONE.zone
  [ ! -f "$ZONE_FILE" ] && echo "Error: Please create zone file first" && exit 1
  DS_FILE=/var/lib/unbound/$ZONE.ds.key
  # 
  # 第一步：生成密钥对，到 KEY_DIR
  rm $KEY_DIR/* 2>/dev/null
  dnssec-keygen -n ZONE -v 9 -a RSASHA512 -b 2048 -K $KEY_DIR $ZONE
  KEY_FILE=$(ls -1 $KEY_DIR/*.key|tail -1 2>/dev/null)
  rm $ZONE.key 2>/dev/null
  ln -s $KEY_FILE ./$ZONE.key
  #
  # 第二步：根据公钥生成 DS(Deligation Signer) 记录
  rm $DS_FILE 2>/dev/null
  [ -f "$KEY_FILE" ] && dnssec-dsfromkey  $KEY_FILE |sudo -u unbound tee $DS_FILE
  # 以上生成的 DS_FILE 复制到所有 Linux 客户端: /etc/dnssec-trust-anchors.d/$ZONE.positive
  # 也可以等 zone reload 生效后在 客户端
  # $ dig @dns-server DS $ZONE |grep ^$ZONE|awk '{print $1,$3,$4,$5,$6,$7,$8 $9}' |sudo tee /etc/dnssec-trust-anchors.d/$ZONE.positive
  # 修改 /etc/systemd/resolved.conf，设置 DNSSEC=yes，并设置正确的 DNS Server，重启 systemd-resolved
  #
  # 第三步：对 zone 文件签名
  [  -r "$ZONE_FILE.signed" ] && rm $ZONE_FILE.signed
  dnssec-signzone -S -o $ZONE -K $KEY_DIR -z $ZONE_FILE
  [ $? = 0 ] && echo "Info: Signed zone file as: $ZONE_FILE.signed"
  # zone reload
  unbound-control reload $ZONE
```

  - /etc/unbound/unbound.conf 文件内容：

```
server:                                                                               
        verbosity: 9
        # val-override-date: 20221230  
        val-log-level: 2                                                              
        extended-statistics: no                                                       
        interface: 192.168.99.148
        interface: 127.0.0.1       
        port: 53               
        prefer-ip4: yes     
        access-control: 192.168.0.0/16 allow
        directory: "/etc/unbound"                                                     
        logfile: "/var/lib/unbound/log/unbound.log"
        use-syslog: no       
        log-time-ascii: yes    
        log-queries: yes    
        log-replies: yes   
        log-local-actions: yes                                                        
        log-servfail: yes                              
        trust-anchor-file: "/var/lib/unbound/leisure.linux.ds.key"
        val-permissive-mode: yes
        val-log-level: 1
python:
dynlib:
remote-control:
        control-enable: yes
        control-interface: 127.0.0.1
        control-port: 8953
        control-use-cert: "no"
        server-key-file: "/etc/unbound/unbound_server.key"
        server-cert-file: "/etc/unbound/unbound_server.pem"
        control-key-file: "/etc/unbound/unbound_control.key"
        control-cert-file: "/etc/unbound/unbound_control.pem"
forward-zone:
        name: "." # use for ALL queries
        forward-addr: 176.103.130.132 # adguard-dns-family
        forward-addr: 185.228.168.10 # cleanbrowsing-adult
auth-zone:
        name: "leisure.linux"
        primary: 192.168.99.148
        fallback-enabled: no
        for-downstream: yes
        zonefile: "leisure.linux.zone.signed"
include-toplevel: "/etc/unbound/unbound.conf.d/*.conf"
```

