#### Arch Linux 
  1. 安装 AUR 的工具： yay
    - $ sudo pacman -Syu
    - $ sudo pacman -S git base-devel
    - $ git clone https://aur.archlinux.org/yay.git
    - $ cd yay && makepkg -sri
    - $ yay -S <pkgname> , 安装软件包
    - $ 其他用法
      - $ yay -Ss:搜索 
      - $ yay -Si:查看信息
      - $ yay -Pu:检查需要更新的软件包
      - $ yay -Yc:清除不需要的依赖
      - $ yay -Rs:删除软件包及其依赖
  2. 使用最近的镜像源
    - $ sudo pacman -S pacman-contrib
    - $ curl \-s "https://archlinux.org/mirrorlist/?country=CN&usr_mirror_status=on" |sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - |tee /etc/pacman.d/mirrorlist
  3. 安装 gnome & gdm
    - $ sudo pacman \-S xorg xorg-server
    - $ sudo pacman \-S gnome gdm gnome-tweaks
    - $ sudo systemctl \-\-now enable gdm.service
    - 或者安装其他 DM: lxdm, lightdm
  4. 中文的支持
    - [参考](https://wiki.archlinux.org/title/Localization_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87\)/Simplified_Chinese_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87\))
    - $ grep \-v ^# /etc/locale.gen
        ` en_US.UTF-8 UTF-8  
        ` zh_CN.UTF-8 UTF-8
    - $ locale\-gen 

  5. 升级到搜狗拼音 4.0 
    - [参考文档](https://aur.archlinux.org/packages/fcitx-sogoupinyin) 
    - 安装： $ yay -S fcitx-sogoupinyin 

    - [PKG 下载](http://cdn2.ime.sogou.com/dl/gzindex/1646897940/sogoupinyin_4.0.0.1605_amd64.deb) 

    - vim ~/.xprofile 
        ` export LANG=zh_CN.UTF-8 
          export LANGUAGE=zh_CN:en_US 
          export LC_ALL=zh_CN.UTF-8 
          export GTK_IM_MODULE=fcitx 
          export QT_IM_MODULE=fcitx 
          export XMODIFIERS="@im=fcitx"

  6. 微信的安装
    - [参考](https://aur.archlinux.org/packages/deepin-wine-wechat)
    - [Wine 的 archlinux Wiki](https://wiki.archlinux.org/title/wine)
    - [微信聊天界面字体的问题](https://unix.stackexchange.com/questions/496135/chinese-characters-in-wine)
  7. 开启 serial console
    - $ vim /etc/default/grub
    GRUB_TERMINAL_INPUT="console serial"
    GRUB_TERMINAL_OUTPUT="gfxterm serial"
    GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200"
    GRUB_CMDLINE_LINUX_DEFAULT="rootflags=compress-force=zstd console=tty0 console=ttyS0,115200"
    - # grub-mkconfig -o /boot/grub/grub.cfg
    - 重启后， cat /proc/cmdline ， 在主机上 virsh console domain-name
  8. 安装和启用 budgie
    - $ yay -S budgie-desktop
  9. 安装 flatpak 软件商城
    - $ sudo pacman -S flatpak
    - $ sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    - $ sudo flatpak remotes
    - $ flatpak install <pkgname>
