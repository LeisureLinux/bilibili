#### 命令行读取系统信息的工具 INXI

##### 基本句法：
  - inxi [-AbBCdDEfFGhiIjJlLmMnNopPrRsSuUVwyYzZ]
  - inxi   [-c   NUMBER]  [--sensors-exclude  SENSORS]  [--sensors-use  SENSORS]  [-t  [c|m|cm|mc][NUMBER]]  [-v  NUMBER]  [-W  LOCATION]
       [--weather-unit {m|i|mi|im}] [-y WIDTH]
  - inxi [--edid] [--gpu] [--memory-modules] [--memory-short] [--recommends] [--sensors-default] [--slots]
  - inxi [-x|-xx|-xxx|-a] -OPTION(s)

##### 基本功能
  - 系统硬件
  - CPU
  - 驱动
  - Xorg
  - 桌面
  - 内核
  - gcc 版本
  - 处理器
  - 内存
  - GPU
  - 电池
  - 等等

#### 标准选项
### -A , --audio: 声卡信息，-xxA 显示所有检测到的声音服务
      * -b , --basic: 显示基本输出，另外一个相同的命令是 inxi -v 2
### -B , --battery: 显示电池信息
      * -c , --color: 以颜色输出
### -C , --cpu: 输出所有 CPU 信息
              - 类型解释：
                * AMCP -  非对称多核处理器
                * AMP - 非对称多处理器
                * MT - Multi/Hyper Threaded CPU, 多线程/超线程处理器 
                * MST - Multi and Single Threaded CPU 
                * MCM - Multi Chip Model (more than 1 die per CPU).
                * MCP - Multi Core Processor (more than 1 core per CPU).
                * SMP - Symmetric Multi Processing (more than 1 physical CPU).
                * UP - Uni (single core) Processor.

       * -d , --disk-full,--optical: 在 -D 硬盘数据以外显示光驱数据，同时也显示软驱数据
### -D , --disk: 显示硬盘信息
### -E, --bluetooth: 显示蓝牙信息
       * --edid: 图形方式显示 EDID 数据
       * --filter, -z: 过滤选项，详细见 FILTER
       * -f , --flags: 显示所有 CPU 旗标
       * -F , --full: 完整输出
       * --gpu: 显示高级 GPU 数据 --nvidia, --nv 
### -G , --graphics: 显示显卡信息 -Gxx 显示监视器数据 --edid 显示高级的监视器数据
       * -h , --help: 帮助
       * -i , --ip: 显示公网 IP 以及本地网卡
       * -I , --info
       * -j, --swap: 交换分区
### -J , --usb: USB 信息
       * -l , --label: 分区标签
       * -L, --logical: 逻辑卷信息
### -m , --memory: 内存
       * --memory-modules, --mm: 仅显示内存阵列和模块
       * --memory-short, --ms: 一行显示内存信息
### -M , --machine: 显示机器信息
       * -n , --network-advanced: 网络
### -N , --network: 网卡
       * -o , --unmounted: 未挂接的分区信息
       * -p , --partitions-full: 完整的分区信息
       * -P , --partitions: 基本的分区信息
       * --processes See -t.
### -r , --repos: 显示软件库信息,目前支持
              APK (Alpine Linux + derived versions)
              APT (Debian, Ubuntu + derived versions, as well as RPM based APT distros like PCLinuxOS or Alt-Linux)
              * CARDS (NuTyX + derived versions)
              * EOPKG (Solus)
              * NIX (NixOS + other distros as alternate package manager)
              PACMAN (Arch Linux, KaOS + derived versions)
              PACMAN-G2 (Frugalware + derived versions)
              * PISI (Pardus + derived versions)
              * PKG (OpenBSD, FreeBSD, NetBSD + derived OS types)
              * PORTAGE (Gentoo, Sabayon + derived versions)
              * PORTS (OpenBSD, FreeBSD, NetBSD + derived OS types)
              * SCRATCHPKG (Venom + derived versions)
              * SLACKPKG (Slackware + derived versions)
              TCE (TinyCore)
              * URPMI (Mandriva, Mageia + derived versions)
              * XBPS (Void)
              YUM/ZYPP (Fedora, Red Hat, Suse + derived versions)
       * -R , --raid: RAID 信息
### --recommends: 查看 inxi 需要的依赖以及建议安装的软件
       * -s , --sensors: 传感器
       * --slots: PCI 
### -S , --system: 系统
       * -t , --processes: top CPU & Memory
       * -t c: top CPU only
       * -t m: top memory only
       * -t cm: top CPU+memory
       * -u , --uuid: 分区的 UUID
       * -U , --update: 软件更新
       * -v , --verbosity, 支持 0-8 详细级别，默认 0

#### 过滤选项
       --filter , --filter-override See -z, -Z.
       --filter-label, --filter-uuid, --filter-vulnerabilities See --zl, --zu, --zv.
       --host Turns on hostname in System line. Overrides inxi config file value (if set):
              SHOW_HOST='false' - Same as: SHOW_HOST='true'
              This is an absolute override, the host will always show no matter what other switches you use.
       --no-host Turns  off  hostname  in System line. 
       -z, --filter Adds security filters for IP addresses, serial numbers, MAC, location (-w), and user home directory name. Removes Host:. On by default for IRC clients.
       --zl, --filter-label
              Filter partition label names from -j, -o, -p, -P, and -Sa (root=LABEL=...). Generally only useful in very specialized cases.
       --zu, --filter-uuid
              Filter partition UUIDs from -j, -o, -p, -P, and -Sa (root=UUID=...). Generally only useful in very specialized cases.
       --zv, --filter-v, --filter-vulnerabilities
              Filter Vulnerabilities report from -Ca. Generally only useful in very specialized cases.
       -Z , --filter-override , --no-filter
              Absolute override for output filters. Useful for debugging networking issues in IRC for example.

#### 输出控制：
    - 颜色
       -c , --color [0-42] : 显示颜色模式
       -c [94-99]
       -c 94  - Console, out of X.
       -c 95  - Terminal, running in X - like xTerm.
       -c 96  - GUI IRC, running in X - like XChat, Quassel, Konversation etc.
       -c 97  - Console IRC running in X - like irssi in xTerm.
       -c 98  - Console IRC not in X.
       -c 99  - Global - Overrides/removes all settings.
    - 缩进模式
       --indent [11-xx]
       --indents [0-10]
       --limit [-1 - x]
       --max-wrap, --wrap-max [integer]
       --output [json|screen|xml]
       --output-file [full path to output file|print]
       --partition-sort [dev-base|fs|id|label|percent-used|size|uuid|used]
       --wrap-max [integer]
       -y, --width [integer]
       -Y, --height, --less [-3-[integer]

#### 管理附加数据
       --admin 选项设置了  -xxx
       -a -A  : 声音服务
       -a -C : CPU
       -a -d,-a -D: 磁盘
       -a -E (--bluetooth): 蓝牙
       -a -G  : 图形卡
       -a -I : 软件包
       -a -j, -a -P [swap], -a -P [swap]: 交换分区
       -a -L : 逻辑卷(LV)
       -a -m : 内存
       -a -n, -a -N, -a -i: 网卡
       -a -o :  设备的分区信息
       -a -p,-a -P : 分区信息
       -a -r  - Adds Packages. See -Ia
       -a -R  - Adds device kernel major:minor number (mdraid, Linux only).
       -a -S  - Adds kernel boot parameters to Kernel section (if detected). Support varies by OS type.
       -a --slots: PCI 信息

#### 高级选项
       --alt 40 Bypass Perl as a downloader option. Priority is: Perl (HTTP::Tiny), Curl, Wget, Fetch, (OpenBSD only) ftp.
       --alt 41 Bypass Curl as a downloader option. Priority is: Perl (HTTP::Tiny), Curl, Wget, Fetch, (OpenBSD only) ftp.
       --alt 42 Bypass Fetch as a downloader option. Priority is: Perl (HTTP::Tiny), Curl, Wget, Fetch, (OpenBSD only) ftp.
       --alt 43 Bypass Wget as a downloader option. Priority is: Perl (HTTP::Tiny), Curl, Wget, Fetch, OpenBSD only: ftp
       --alt 44 Bypass Curl, Fetch, and Wget as downloader options. This basically forces the downloader selection to use Perl 5.x HTTP::Tiny, which is generally slower than Curl or Wget but it may help bypass issues with downloading.
       --bt-tool [bt-adapter|hciconfig|rfkill] Force the use of the given tool for bluetooth report (-E). rfkill does not support mac address data.
       --dig  Temporary override of NO_DIG configuration item. Only use to test w/wo dig. Restores default behavior for WAN IP, which is use dig if present.
       --display [:<integer>]
       --dmidecode Shortcut. See --force dmidecode.
       --downloader [curl|fetch|perl|wget] Force inxi to use Curl, Fetch, Perl, or Wget for downloads.
       --force [colors|dmidecode|hddtemp|lsusb|pkg|usb-sys|wayland|vmstat|wmctrl]
              Various force options to allow users to override defaults. Values can be given as a comma separated list:

              inxi -MJ --force dmidecode,lsusb
              - colors - Same as -Y -2 . Do not remove colors from piped or redirected output.
              - dmidecode - Force use of dmidecode. This will override /sys data in some lines, e.g. -M or -B.
              - hddtemp - Force use of hddtemp instead of /sys temp data for disks.
              -  lsusb  -  Forces  the  USB  data  generator  to use lsusb as data source (default). Overrides USB_SYS in user configuration file(s).
              - pkg - Force override of disabled package counts. Known package managers with non-resolvable issues:

              - usb-sys - Forces the USB data generator to use /sys as data source instead of lsusb (Linux only).
              - vmstat - Forces use of vmstat for memory data.
              - wayland - Forces use of Wayland, disables x tools glxinfo, xrandr, xdpyinfo.
              - wmctrl - Force System item wm to use wmctrl as data source, override default ps source.
       --hddtemp Shortcut. See --force hddtemp.
       --html-wan Temporary  override of NO_HTML_WAN configuration item. Only use to test w/wo HTML downloaders for WAN IP. Restores default behavior for WAN IP, which is use HTML downloader if present and if dig failed.
       --man  Updates / installs man page with -U if pinxi or using -U 3 dev branch. (Only active if -U is is not disabled by maintainers).
       --no-dig Overrides default use of dig to get WAN IP address. Allows use of normal downloader tool to get IP addresses. Only use if  dig is failing, since dig is much faster and more reliable in general than other methods.
       --no-doas Skips the use of doas to run certain internal features (like hddtemp, file) with doas. Not related to running inxi itself with doas/sudo or super user. Some systems will register errors which will then trigger admin emails in such cases, so if you  want to  disable regular user use of doas (which requires configuration to setup anyway for these options) just use this option, or NO_DOAS configuration item. See --no-sudo if you need to disable both types.
       --no-html-wan Overrides use of HTML downloaders to get WAN IP address. Use either only dig, or do not get wan IP. Only use if dig  is  failing, and the HTML downloaders are taking too long, or are hanging or failing.
       --no-man Disables  man  page install with -U for master and active development branches. (Only active if -U is is not disabled by maintainers).
       --no-sensor-force Overrides user set SENSOR_FORCE configuration value. Restores default behavior.
       --no-ssl Skip SSL certificate checks for all downloader actions (-U, -w, -W, -i). Use if your system does not have current SSL certificate lists, or if you have problems making a connection for any reason. Works with Wget, Curl, Perl HTTP::Tiny and Fetch.
       --no-sudo Skips the use of sudo to run certain internal features (like hddtemp, file) with sudo. Not related to running inxi itself with sudo or superuser. Some systems will register errors which will then trigger admin emails in such cases
       --pkg  Shortcut. See --force pkg.
       --pm-type [package manager name] For distro package maintainers only, and only for non apt, rpm, or pacman based systems. To be used to test replacement  package lists for recommends for that package manager.
       --sensors-default Overrides configuration values SENSORS_USE or SENSORS_EXCLUDE on a one time basis.
       --sensors-exclude Similar  to  --sensors-use  except  removes listed sensors from sensor data. Make permanent with SENSORS_EXCLUDE configuration item. Note that gpu, network, disk, and other specific device monitor chips are excluded by default.
       --sensors-use Use only the (comma separated) sensor arrays for -s output. Make permanent with SENSORS_USE configuration item.  Sensor  array ID  value  must be the exact value shown in lm-sensors sensors output (Linux/lm-sensors only). If you only want to exclude one (or more) sensors from the output, use --sensors-exclude.
       --sleep [0-x.x]
              Usually  in  decimals. Change CPU sleep time for -C (current:  .35).  Sleep is used to let the system catch up and show a more accurate CPU use.  
       --tty  Forces internal IRC flag to off. Used in unhandled cases where the program running inxi may not be seen  as  a  shell/pty/tty, but  it is not an IRC client.  Put --tty first in option list to avoid unexpected errors. If you want a specific output width, use the --width option. If you want normal color codes in the output, use the -c [color ID] flag.
       --usb-sys Shortcut. See --force usb-sys
       --usb-tool Shortcut. See --force lsusb
       --wan-ip-url [URL] Force -i to use supplied URL as WAN IP source. Overrides dig or default IP source urls. URL must start with http[s] or ftp.
       --wayland, --wl Shortcut. See --force wayland.
       --wm   Shortcut. See --force wmctl.

#### 调试选项（略）
       --dbg {[1-x][,[1-x]]}
       --debug [1-3] - On screen debugger output.
       --debug 10 - Basic logging. Check $XDG_DATA_HOME/inxi/inxi.log or $HOME/.local/share/inxi/inxi.log or $HOME/.inxi/inxi.log.
       --debug 11 - Full file/system info logging.
       --debug 20
              Creates a tar.gz file of system data and collects the inxi output in a file.
              * tree traversal data file(s) read from /proc and /sys, and other system data.
              * xorg conf and log data, xrandr, xprop, xdpyinfo, glxinfo etc.
              * data from dev, disks, partitions, etc.
       --debug 21 Automatically  uploads  debugger data tar.gz file to ftp.smxi.org, then removes the debug data directory, but leaves the debug tar.gz file.  See --ftp for uploading to alternate locations.
       --debug 22 Automatically uploads debugger data tar.gz file to ftp.smxi.org, then removes the debug data directory and  the  tar.gz  file. See --ftp for uploading to alternate locations.
       --fake-data-dir Developer only: Change default location of $fake_data_dir, which is where files are for --fake {item} items.
       --ftp [ftp.yoursite.com/incoming] For alternate ftp upload locations: Example: inxi --ftp ftp.yourserver.com/incoming --debug 21

#### 配置文件
       inxi will read its configuration/initialization files in the following order:
       /etc/inxi.conf  contains  the  default configurations. These can be overridden by creating a /etc/inxi.d/inxi.conf file (global override, which will prevent distro packages from changing or overwriting your edits. This method is recommended if you are using a  distro packaged inxi and want to override some configuration items from the package's default /etc/inxi.conf file but don't want to lose your changes on a package update.
       You can old override, per user, with a user configuration file found in one of the following locations (inxi will  store  its  config file using the following precedence:
       if  $XDG_CONFIG_HOME  is  not empty, it will go there, else if $HOME/.conf/inxi.conf exists, it will go there, and as a last default, the legacy location is used), i.e.: $XDG_CONFIG_HOME/inxi.conf > $HOME/.conf/inxi.conf > $HOME/.inxi/inxi.conf

#### 配置选项：
       See the documentation page for more complete information on how to set these up, and for a complete list of options:
       https://smxi.org/docs/inxi-configuration.htm

       Basic Options
              Here's a brief overview of the basic options you are likely to want to use:

            *  COLS_MAX_CONSOLE The max display column width on terminal. 
            *  COLS_MAX_IRC The max display column width on IRC clients.
            *  COLS_MAX_NO_DISPLAY The max display column width in out of X / Wayland / desktop / window manager.
            *  CPU_SLEEP  Decimal  value  0  or  more. Default is usually around 0.35 seconds. Time that inxi will 'sleep' before getting CPU speed data, so that it reflects actual system state.
            *  DOWNLOADER Sets default inxi downloader: curl, fetch, ftp, perl, wget.  See --recommends output for more information on  downloaders and Perl downloaders.
            *  FILTER_STRING Default <filter>. Any string you prefer to see instead for filtered values.
            *  INDENT Change primary indent width of wide mode output. See --indent.
            *  INDENTS Change primary indents of narrow wrapped mode output, and second level indents. See --indents.
            *  LIMIT  Overrides  default  of  10 IP addresses per IF. This is only of interest to sys admins running servers with many IP addresses.
            *  LINES_MAX Values: [-2-xxx]. See -Y for explanation and values.  Use -Y -3 to restore default unlimited output lines. Avoid using this in general unless the machine is a headless system and you want the output to be always controlled.
            *  MAX_WRAP (or WRAP_MAX) The maximum width where the line starter wraps to its own line. If terminal/console width or --width is less than wrap width, wrapping of line starter occurs. Overrides default. See --max-wrap. If 80 or less, wrap will never  happen.
            *  NO_DIG Set to 1 or true to disable WAN IP use of dig and force use of alternate downloaders.
            *  NO_DOAS Set to 1 or true to disable internal use of doas.
            *  NO_HTML_WAN  Set  to 1 or true to disable WAN IP use of HTML Downloaders and force use of dig only, or nothing if dig disabled as well. Same as --no-html-wan. Only use if dig is failing, and HTML downloaders are hanging.
            *  NO_SUDO Set to 1 or true to disable internal use of sudo.
            *  PARTITION_SORT Overrides default partition output sort. See --partition-sort for options.
            *  PS_COUNT The default number of items showing per -t type, m or c. Default is 5.
            *  SENSORS_CPU_NO In cases of ambiguous temp1/temp2 (inxi can't figure out which is the CPU), forces sensors to use either  value 1 or 2 as CPU temperature. See the above configuration page on smxi.org for full info.
            *  SENSORS_EXCLUDE Exclude supplied sensor array[s] from sensor output.  Override with --sensors-default. See --sensors-exclude.
            *  SENSORS_USE Use only supplied sensor array[s]. Override with --sensors-default. See --sensors-use.
            *  SEP2_CONSOLE Replaces default key / value separator of ':'.
            *  USB_SYS Forces all USB data to use /sys instead of lsusb.
            *  WAN_IP_URL  Forces -i to use supplied URL, and to not use dig (dig is generally much faster). URL must begin with http or ftp.
            *  WEATHER_SOURCE  Values:  [0-9].  Same as --weather-source.  Values 4-9 are not currently supported, but this can change at anytime.
            *  WEATHER_UNIT Values: [m|i|mi|im]. Same as --weather-unit.
            *  CONSOLE_COLOR_SCHEME The color scheme for console output (not in X/Wayland).
            *  GLOBAL_COLOR_SCHEME Overrides all other color schemes.
            *  IRC_COLOR_SCHEME Desktop X/Wayland IRC CLI color scheme.
            *  IRC_CONS_COLOR_SCHEME Out of X/Wayland, IRC CLI color scheme.
            *  IRC_X_TERM_COLOR_SCHEME In X/Wayland IRC client terminal color scheme.
            *  VIRT_TERM_COLOR_SCHEME Color scheme for virtual terminal output (in X/Wayland).
            *  FAKE_DATA_DIR - change default fake data directory location. See --fake-data-dir.

HOMEPAGE
       https://github.com/smxi/inxi
       https://smxi.org/docs/inxi.htm
