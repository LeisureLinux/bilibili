### DE/DW/WM

- DE(Desktop Environment) 介绍

  - 基于 GTK
    - Budgie
    - Cinnamon
    - GNOME：GNU Network Obeject Model Environment，不再是 GNU
      - 2002 年 6 月 GNOME 2 发布，到 2009 年，是 OpenSolaris 的默认桌面。 MATE 是 GNOME 2 的分叉
      - GNOME3 或者 GNOME Shell 发布于 2011 年， Mutter WM 取代了 Metacity ， 默认 Adiwata 主题
      - GNOME 40 于 2021 年 3 月发布
    - GPE
    - LXDE
    - MATE
    - ROX Desktop
    - Sugar
    - Xfce (直到 2019 年 11 月 1.0.5 版本，还不支持 Wayland)
  - 基于 Qt
    - Deepin
    - KDE Plasma
    - Lumina
    - LXQT
    - OPIE
    - Trinity
  - 基于 Motif
    - CDE
    - DECwindows Motif
    - IRIS
    - VUE
  - 其他
    - EDE
    - Mezzo
    - UDE
    - Enlightenment

- X display manager (XDM)，又称为 Greeters，

  - GDM (GNOME)
  - SDDM (KDE)
  - LightDM (Canonical)
    - 也支持 Wayland
    - 支持远程 Login ( XDMCP，VNC)
    - 标准兼容 (PAM，logind)
    - 跨桌面（greeter 可以用各种 toolkit 编写）
    - Greeter
      - Arctica
      - Deepin
      - GTK: Xubuntu
      - Mini
      - Pantheon: elementary OS
      - Qt5
      - Slick: Linux Mint
      - WebEngine
      - Web
      - WebKit2

- 图形 Shell

  - Deepin
  - GNOME Shell
    - 2011 年 4 月发布，取代了 GNOME Panel，用 C 和 JS 写成，是 Mutter 的插件
    - 界面设计分为 7 个部分
      1. Top bar
      2. System status area(右上角系统状态栏)
      3. Activities Overview
      4. Dash（任务栏）
      5. Window picker
      6. Application picker
      7. Search
      8. Notifications and messaging tray
      9. Application switcher
      10. Indicators tray(被废弃)
  - KDE Plasma 4
  - KDE Plasma 5
  - Maynard
  - Unity

- X Windows 管理器 (WM)

  - 合成

    - Compiz
    - KWin (KDE Plasma 5，可以使用 QML 或者 QtScript 来配置)
    - Metacity
    - Mutter
      - 最初是为 X 设计的，后来也支持 Wayland
      - GNOME3 的默认 WM，取代了 Metacity
      - 名称来源： Metacity + Cl**utter**
    - uffin， Cinnamon DE 上的 Mutter 的分叉
    - Xfwm
    - Enlighenment

  - 堆叠
    - 4Dwm
    - 9wm
    - AfterStep
    - amiwm
    - Blackbox
    - CTWM
    - cwm
    - FLuxbox
    - FLWM
    - FVWM
    - IceWM
    - JWM
    - Matchbox
    - Motif Window Manager
    - olwm
    - Openbox
    - Qvwm
    - Sawfish
    - swm
    - twm
    - tvtwm
    - vtwm
    - Winodw Maker
    - WindowLab
    - wm2
  - 平铺
    - awesome
    - dwm
    - i3
    - Ion
    - 1arswm
    - ratpoison
    - StumpWM
    - wmii
    - xmonad

- Wayland 合成器(Display Server 协议，目标是取代 X Window)

  - Englightenment
  - Gala
  - KWinMir
  - Mutter
  - Muffin
  - Budgiewm
  - sway
  - Weston

- Cinnamon(肉桂) 桌面环境(DE) 介绍

  - For X Windows
  - Derive from GNOME3
  - Principal DE for Linux Mint
  - 2011 年 4 月发布的 GNOME3 抛弃了传统的 GNOME2 的一些桌面特色，以 GNOME SHELL 取代
  - 2013 年 10 月，Mint 的团队发布 Cinnamon 2.0 正式和 GNOME 分裂
  - Applets 和 Desklets 不再和 GNOME3 兼容
  - Cinnamon 和 Xfce 以及 GNOME2(Mate) 桌面类似
  - 2012 年 1 月，1.2 版本时， Cinnamon 的窗口管理器(WM) 是 Muffin，是 GNOME3 的 Mutter 的分叉
  - 2012 年 9 月，文件管理器 Nemo 发布，是 Nautilus 的分叉
  - 2013 年 5 月， Cinnamon-Control-Center 包含 GNOME-Control-Center 的功能，并发布 Cinnamon-Settings 管理和更新 Applets, Extensions, Desklets
  - Gnome-Screensaver 也分叉为 Cinnamon-Screensaver
  - 从 2013 年 10 月开始， Cinnamon 不再是 GNOME 桌面的前端，而是一个独立的桌面环境。尽管底层是 GNOME 的技术，并采用 GTK,但是不再需要事先安装 GNOME。
  - X-Apps
    - Xed：基于 Gedit/pluma 的文本编辑器
    - Xviewer：基于 Eye of GNOME 的图片查看器
    - Xreader：基于 Evince 的文档阅读器
    - Xplayer：基于 GNOME Video(Totem)的媒体播放器
    - Pix：基于 gThumb 的照片组织器

- 其他容易搞混的问题

  - Window Manager theme: manages window decoration

    > ie.: how are windows arranged, positioned and presented,
    > and how human interface interacts with them
    > (eg.: border snapping, scroll wheel, global shortcuts, etc).

  - Appearance Theme: manages window contents and font / icon usage
    > ie.: how are applications stylized for the user.
