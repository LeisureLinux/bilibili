#### systemd 解释

- [PID 1](http://0pointer.de/blog/projects/systemd.html)
- [init](https://www.wikiwand.com/en/Init#/SysV-style)
- [launchd](https://www.wikiwand.com/en/Launchd)
  - 2005 年 4 月苹果的服务管理程序，取代 BSD 风格的 init 以及 SystemStarter
  - [油管上关于 Launchd 的一个视频](https://www.youtube.com/watch?v=cD_s6Fjdri8)
  - 包含 launchd 和 launchctl 两个组件
  - Intel Mac 的启动顺序
    1. EFI 激活，初始化硬件，加载 BootX
    2. BootX 加载内核，“旋转风车游标” (pinwheel cursor)，然后加载各种需要的内核扩展(kexts)
    3. 内核加载 launchd
    4. launchd 运行 /etc/rc，各种脚本扫描 /System/Library/LaunchDaemons 以及 /Library/LaunchDaemons，在不同的 plist 文件上调用 lanuchctl ，然后 launchd 启动 登录窗口
- [Solaris SMF](https://www.wikiwand.com/en/Service_Management_Facility)
- telinit 或者 init <n> 切换运行级
- 2010 年红帽的工程师 Lennart Poettering 和 Kay Seivers 开始开发 systemd
- 2011 年 5 月，Fedora 率先采用 systemd 取代 SysVinit
- 2019 年 2 月， systemd 成为绝大多数 Linux 发行版的选择
- 用 systemd-nspawn 来管理容器
