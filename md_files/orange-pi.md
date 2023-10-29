#### 香橙派的升级

##### 事先预备：
  - 香橙派，树莓派，香蕉派，苹果派等各种派（本质上就是一块不超过 100RMB 的带无线，蓝牙，红外，有线网络的 ARM64 的 SOC 单板机）
  - 一块 16GB 或者更大容量的 SD 卡 作为派的启动盘，需要烧写镜像到 SD 卡上
  - 一台有空闲有线网口(千兆口)的无线路由器，一根网线
  - 一台安装了 Debian/Ubuntu Linux 的 PC（建议物理机安装）

##### 烧写镜像并扩容文件系统：
  - 去深圳迅龙或者其他派的官网找自己喜欢的操作系统镜像，下载
  - 下载并启动 balenaEtcher-1.x.x-x64.AppImage ，烧写 p7zip -d 解压后的 img 镜像到 SD 卡，烧写完成后如果系统有自动挂接 SD 卡，则 umount 
  - 重建SD卡根分区以扩容：fdisk /dev/sda, 按 p 查看，确认要删除的分区及其起始扇区号，按 d 删除分区，按 n 新建分区，起始扇区选择之前查看到数字，一般是 8192，结束扇区选默认，就是 SD 卡的末尾，按 w 写入分区后退出
  - 扩容根文件系统从 4GB 到16G：假设分区是 /dev/sda1，则 fsck -y /dev/sda1; resize2fs /dev/sda1 后完成扩容
  - 镜像默认的用户名和密码都是 orangepi
 
##### 挂接 SD 卡的 arm64 操作系统作为"虚机" 到 x86_64 的 Linux 主机上
  - 主机上安装 qemu-user-static 包： # apt-get install qemu-user-static
  - 挂接 SD 卡： # sudo mount /dev/sda1 /mnt
  - 复制 qemu 到 SD 卡： # cp $(which qemu-arm64-static) /mnt/usr/bin
  - 挂接 /proc /sys /dev /dev/pts 到 SD 卡，即：
  ```
   for d in /proc /sys /dev /dev/pts; do
      sudo mount --bind $d /mnt/sys$d
   done
  ```
  - sudo chroot /mnt qemu-arm64-static /bin/bash

##### 升级 SD 卡内的操作系统
  - 进入 chroot 后，修改 /etc/apt/sources.list，bullseye 修改为 bookworm，原先的 repo.huaweicloud.com 修改为 mirror.sjtu.edu.cn
  - # apt update 
  - # **apt remove XXXX**
  - # **apt install bash --reinstall**
  - # **apt upgrade**

##### 验证
  - 把 SD 卡插入到派内，用 Type-C 供电，接上网线
  - 登陆家里的无线路由器的管理界面，找到派，绑定 IP 地址，譬如 192.168.8.8
  - 从 Linux PC 上 ssh orangepi@192.168.8.8 ，大功告成！
  - $ sudo vim /etc/default/orangepi-motd
    MOTD_DISABLE="header tips updates sysinfo config"

