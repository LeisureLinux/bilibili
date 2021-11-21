### XDG 介绍

- 简介：freedesktop.org (fd.o)

  - 一个致力于提升 X11 和 Wayland 上的免费桌面软件之间互操作性和共享的项目
  - 2000 年 3 月由 [Havoc Pennington](https://lwn.net/2000/0427/a/freedesktop.html) 创立
  - 项目服务器位于美国波特兰州立大学
  - 2006 年项目发布了 Portland 1.0 (xdg-utils)
  - 前称：XDG = X Desktop Group
  - 2019 年加入 X.Org 基金会

- 规范

  - 互操作性规范 (Specifications)

    - Autostart
    - [Desktop base directories](https://www.freedesktop.org/wiki/Specifications/basedir-spec/)
    - [Desktop entries(.desktop)](https://www.freedesktop.org/wiki/Specifications/desktop-entry-spec/)
    - [Desktop menus(menu)](https://www.freedesktop.org/wiki/Specifications/menu-spec/)
    - File manager D-Bus 界面
    - [File URIs](https://www.freedesktop.org/wiki/Specifications/file-uri-spec/)
    - 免费媒体播放器规范
    - [Icon themes，图标主题](https://www.freedesktop.org/wiki/Specifications/icon-theme-spec/)
    - 媒体播放器远程界面规范(MPRIS)
    - [共享 MIME 数据库(shared-mime-info)](https://www.freedesktop.org/wiki/Specifications/shared-mime-info-spec/)
    - 启动提醒
    - [垃圾回收](https://www.freedesktop.org/wiki/Specifications/trash-spec/)
    - XML 书签交换语言(XBEL)

  - X11 特定的相关规范
    - DnD， Drag and Drop
    - UTF8 字符串
    - Windows 管理规范
    - XEmbed
    - X 剪贴板
    -
  - 还没被广泛使用的规范草稿
    - MIME 应用规范
    - Icon 命名规范
    - StatusNotifierItem
    - XSETTINGS
    - X Direct Save
    - Sound Theme Spec
    - Secret Storage Spec
    - Desktop Bookmark Spec
    - 。。。

- 软件

  - 服务器上部署管理的著名项目

    - 桌面中间件以及框架
      - AccountsService，本地用户的账号信息
      - D-Bus，消息总线
      - Geoclue，位置信息服务
      - PolicyKits，允许非特权应用配置和存取特权服务和界面
      - NetworkManager，网络管理服务
      - realmd，允许客户端发现，认证并加入类似活动目录的网络
      - upower/udisks/urfkill/media-player-info，提供电池的充放电信息,更多其他的 DeviceKit
      - Zeitgeist，桌面事件日志框架
    - 桌面特性以及帮助器（跨桌面标准的互操作性）
      - dekstop-file-utils
      - icon-theme
      - pyxdg
      - shared-mime-info
      - startup-notification
      - xdg-utils
      - xdg-user-dirs
    - 图形驱动，窗口系统以及支持的库

      - Cairo，向量图形库
      - Beignet，OpenCL 实现
      - DRM，Linux 内核的图形子系统
      - drm_hwcomposer ，安卓的 HWComposer 后台
      - Mesa，对 OpenGL，OpenGL ES，Vulkan，EGL，GLX 渲染 API 的硬件加速和软件实现
      - Pixman，2D 像素操作库
      - Plymouth，提供开机画面以及引导更新显示
      - Wayland
      - X.Org 服务（X11 协议的官方参考实现）

        - XCB，一个 Xlib 的替代
        - Xephyr，X 中的 X ，主要用于测试
        - xsettings
        - xwininfo

    - 输入，i18n 以及字体渲染

      - fontconfig，用于字体发现，名称替换的一个库
        - Xft，使用 FreeType 库的抗锯齿字体
      - FreeType，TrueType 字体渲染库
      - libinput，在 Wayland 中用于处理输入设备
        - libevdev，内核的事件设备包裹库
      - xkeyboard-config，XKB 键盘布局的仓库，大多数桌面和窗口都在使用

    - 多媒体和图形支持

      - Farsteam，网络流媒体互联（点对点直播？）
      - GStreamer，流媒体框架
      - libnice，使用 ICE 协议实现 NAT 背后的点对点连接
      - libopenraw，照片 RAW 格式的解码和处理
      - libespectre， PostScript 的渲染库
      - media-player-info，外部视频播放器设备描述
      - Poppler (PDF 库)
      - PulseAudio，一个声音服务的前端
      - VDPAU，视频解码加速

    - 其他硬件支持
      - cups-pk-help，CUPS 打印服务基于 PolicyKit 的认证集成
      - fprint，指纹驱动
      - ModemManager，DBus 系统服务，为移动宽带猫提供统一的 API
        - libmbim
        - libqmi
    - 其他项目

      - Bustle，录制并显示 D-Bus 流量
      - CppUnit，C++ 测试框架
      - kmscon，KMS/DRM 的系统 console
      - libbsd，BSD 系统里的一些 utility 库
      - [pkg-config](https://www.bilibili.com/video/BV1kM4y1A7Re/)，用于生成编译器和连接器需要依赖的(-I, -l)标记
      - Slirp，Hypervisor 上的 TCP-IP 模拟器
      - SPICE，为虚拟机提供远程存取
      - SyncEvolution，在设备和服务之间提供日历和联系人的同步

    - 已经移出到其他地方的项目(节选)
      - Avahi(零配置实现) ，已经独立成为一个项目
      - Clipart，一个开源的 clipart 仓库
      - systemd，取代旧的 init 服务启停模式
      - Flatpak，沙箱桌面应用打包管理工具
      - HarfBuzz， OpenType 布局引擎
      - LibreOffice
      - OHM，温度和风扇传感器的监控
      - PackageKit 允许用户发现和安装软件包
      - Telepathy，实时通信框架
      - Tracker，文件索引器，元数据收割机
      - udisks，管理存储设备
      - GTK-Qt 引擎
