#### 编译自己的 OpenWrt 镜像
  - [初心](https://github.com/TheMMcOfficial/cups-for-openwrt) 是为了加一个 cups 打印程序，不小心变成了全流程镜像定制
     ' git clone https://github.com/lede-project/source
     ' cd source
     ' echo "src-git cups https://github.com/TheMMcOfficial/lede-cups.git" >> feeds.conf.default
     ' ./scripts/feeds update -a
     ' ./scripts/feeds install -a
     ' make menuconfig
     ' (set the target system to your router "Platform" and set Network->Printing->cups as "M")
     ' make -j4 v=S
  - 常用的软件： file, ss, netcat(nc), pstree, ps,tree,jq,
  - 对应的软件包： file, socat, netcat, psmisc, procps-ng, tree, jq

##### 学习到的成果 
  - [Opkg package manager](https://openwrt.org/docs/guide-user/additional-software/opkg)
    - 修改成阿里云镜像： sed -i 's_downloads.openwrt.org_mirrors.aliyun.com/openwrt_' /etc/opkg/distfeeds.conf
  - [procd](https://openwrt.org/docs/techref/procd)
  - [MTD (Memory Technology Device)](https://openwrt.org/docs/techref/mtd)
  - [The OpenWrt Flash Layout](https://openwrt.org/docs/techref/flash.layout)
  - [OpenWrt File System Hierarchy/Memory Usage](https://openwrt.org/docs/techref/file_system)
  - [Sysupgrade – Technical Reference](https://openwrt.org/docs/techref/sysupgrade)
    - [命令行升级](https://openwrt.org/docs/guide-user/installation/sysupgrade.cli)
  - [定制文件](https://openwrt.org/docs/guide-user/additional-software/imagebuilder)
    - [UCI defaults](https://openwrt.org/docs/guide-developer/uci-defaults)
  - [版本号的计算](https://openwrt.org/docs/guide-developer/source-code/source-revision-calculation)
