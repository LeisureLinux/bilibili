#### 如何学习 Linux (Ver 0.2.20221015)
##### 1. 安装一个操作系统
  - 虚拟机：在 Windows 上用 Oracle VirtualBox 安装一个 Ubuntu 22.04 LTS 的桌面版本
  - 物理机：在 Windows 上用 Rufus 或者 balenaEtcher，烧写 Ubuntu 22.04 LTS 桌面版本到 U盘上，从 U盘启动后安装到笔记本上
##### 2. 选择适合自己的 Terminal/Shell
  - 建议 Gnome Terminal，了解一些基本配置
  - 建议 使用 Byobu(tmux) + Ohmyzsh 
##### 3. 学习 vim，安装 Neovim
  - 了解 vim 插件，安装适合自己的 vim 插件
##### 4. 多看系统自带的 shell 脚本，学习 bash
  - 熟悉 shell 基本语法，了解管道，重定向, /dev/null,/dev/zero, /dev/random 
  - 学习 awk/sed/grep ，三大命令的基本的一些命令行参数都必须了如指掌
    - awk 如何传递参数？
    - awk 自带的 NF/NR 等变量代表的含义？
    - sed 如何做 inline replace
    - sed 如何抓取有特征的某个区块，例如： dpkg-query -s|sed -n '/Package: zsync/,/^$/p'
    - grep 如何按单词筛选，如何不区分大小写筛选（最最基本的能力）
    - 其他外围命令，例如: cut/tr 
##### 5. 进程管理和文件系统管理
  - ps 命令以及 pstree 命令
  - kill 命令以及信号的类型
  - top/htop, 比较高级的 vmstat 命令的输出的各个列的含义
  - 用 findmnt 命令了解文件系统的类型 
  - 了解 swap 的作用
  - 用 lsblk 命令查看块设备
##### 6. 了解 systemctl 命令的语法
  - 知晓 ps 1 的概念
  - 了解 systemd 相关的服务
##### 7. 修改 DNS/NTP 配置
  - 了解 ip 命令语法
  - 了解 NetworkManager(桌面版本)
  - 了解 Netplan (服务器版本)
  - 了解 systemd-resolved
  - 了解 systemd-timesyncd
##### 8. 包管理
  - apt,apt-get,apt-cache
  - /etc/apt/sources.list

##### 最后，永远学会使用 man 手册，或者 command --help 来帮助对命令的理解

