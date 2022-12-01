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
30-systemd-environment-d-generator (8) - Load variables specified by environment.d
deb-systemd-helper (1p) - subset of systemctl for machines not running systemd
deb-systemd-invoke (1p) - wrapper around systemctl, respecting policy-rc.d
dh_installsystemd (1) - install systemd unit files
dh_installsystemduser (1) - install systemd unit files
dh_installsysusers (1) - install and integrates systemd sysusers files
dh_systemd_enable (1) - enable/disable systemd unit files
dh_systemd_start (1) - start/stop/restart systemd unit files
gnome-logs (1)       - log viewer for the systemd journal
init (1)             - systemd system and service manager
journalctl (1)       - Query the systemd journal
libnss_systemd.so.2 (8) - UNIX user and group name resolution for user/group lookup via Varlink
loader.conf (5)      - Configuration file for systemd-boot
loginctl (1)         - Control the systemd login manager
machinectl (1)       - Control the systemd machine manager
networkd-dispatcher (8) - Dispatcher service for systemd-networkd connection status changes
nfs.systemd (7)      - managing NFS services through systemd.
nss-systemd (8)      - UNIX user and group name resolution for user/group lookup via Varlink
oomctl (1)           - Analyze the state stored in systemd-oomd
oomd.conf (5)        - Global systemd-oomd configuration files
oomd.conf.d (5)      - Global systemd-oomd configuration files
org.freedesktop.hostname1 (5) - The D-Bus interface of systemd-hostnamed
org.freedesktop.import1 (5) - The D-Bus interface of systemd-importd
org.freedesktop.locale1 (5) - The D-Bus interface of systemd-localed
org.freedesktop.login1 (5) - The D-Bus interface of systemd-logind
org.freedesktop.machine1 (5) - The D-Bus interface of systemd-machined
org.freedesktop.network1 (5) - The D-Bus interface of systemd-networkd
org.freedesktop.oom1 (5) - The D-Bus interface of systemd-oomd
org.freedesktop.portable1 (5) - The D-Bus interface of systemd-portabled
org.freedesktop.resolve1 (5) - The D-Bus interface of systemd-resolved
org.freedesktop.systemd1 (5) - The D-Bus interface of systemd
org.freedesktop.timedate1 (5) - The D-Bus interface of systemd-timedated
pam_systemd (8)      - Register user sessions in the systemd login manager
rpm-plugin-systemd-inhibit (8) - Plugin for the RPM Package Manager
sd_booted (3)        - Test whether the system is running the systemd init system
systemctl (1)        - Control the systemd system and service manager
systemd (1)          - systemd system and service manager
systemd-analyze (1)  - Analyze and debug system manager
systemd-ask-password (1) - Query the user for a system password
systemd-ask-password-console.path (8) - Query the user for system passwords on the console and v...
systemd-ask-password-console.service (8) - Query the user for system passwords on the console an...
systemd-ask-password-wall.path (8) - Query the user for system passwords on the console and via ...
systemd-ask-password-wall.service (8) - Query the user for system passwords on the console and v...
systemd-backlight (8) - Load and save the display backlight brightness at boot and shutdown
systemd-backlight@.service (8) - Load and save the display backlight brightness at boot and shut...
systemd-binfmt (8)   - Configure additional binary formats for executables at boot
systemd-binfmt.service (8) - Configure additional binary formats for executables at boot
systemd-bless-boot (8) - Mark current boot process as successful
systemd-bless-boot-generator (8) - Pull systemd-bless-boot.service into the initial boot transac...
systemd-bless-boot.service (8) - Mark current boot process as successful
systemd-boot (7)     - A simple UEFI boot manager
systemd-boot-check-no-failures (8) - verify that the system booted up cleanly
systemd-boot-check-no-failures.service (8) - verify that the system booted up cleanly
systemd-boot-system-token.service (8) - Generate an initial boot loader system token and random ...
systemd-cat (1)      - Connect a pipeline or program's output with the journal
systemd-cgls (1)     - Recursively show control group contents
systemd-cgtop (1)    - Show top control groups by their resource usage
systemd-coredump (8) - Acquire, save and process core dumps
systemd-coredump.socket (8) - Acquire, save and process core dumps
systemd-coredump@.service (8) - Acquire, save and process core dumps
systemd-creds (1)    - Lists, shows, encrypts and decrypts service credentials
systemd-cryptenroll (1) - Enroll PKCS#11, FIDO2, TPM2 token/devices to LUKS2 encrypted volumes
systemd-cryptsetup (8) - Full disk decryption logic
systemd-cryptsetup-generator (8) - Unit generator for /etc/crypttab
systemd-cryptsetup@.service (8) - Full disk decryption logic
systemd-debug-generator (8) - Generator for enabling a runtime debug shell and masking specific ...
systemd-delta (1)    - Find overridden configuration files
systemd-detect-virt (1) - Detect execution in a virtualized environment
systemd-dissect (1)  - Dissect file system OS images
systemd-environment-d-generator (8) - Load variables specified by environment.d
systemd-escape (1)   - Escape strings for usage in systemd unit names
systemd-fsck (8)     - File system checker logic
systemd-fsck-root.service (8) - File system checker logic
systemd-fsck@.service (8) - File system checker logic
systemd-fsckd (8)    - File system check progress reporting
systemd-fsckd.service (8) - File system check progress reporting
systemd-fsckd.socket (8) - File system check progress reporting
systemd-fstab-generator (8) - Unit generator for /etc/fstab
systemd-getty-generator (8) - Generator for enabling getty instances on the console
systemd-gpt-auto-generator (8) - Generator for automatically discovering and mounting root, /hom...
systemd-growfs (8)   - Creating and growing file systems on demand
systemd-growfs@.service (8) - Creating and growing file systems on demand
systemd-halt.service (8) - System shutdown logic
systemd-hibernate-resume (8) - Resume from hibernation
systemd-hibernate-resume-generator (8) - Unit generator for resume= kernel parameter
systemd-hibernate-resume@.service (8) - Resume from hibernation
systemd-hibernate.service (8) - System sleep state logic
systemd-hostnamed (8) - Daemon to control system hostname from programs
systemd-hostnamed.service (8) - Daemon to control system hostname from programs
systemd-hwdb (8)     - hardware database management tool
systemd-hybrid-sleep.service (8) - System sleep state logic
systemd-id128 (1)    - Generate and print sd-128 identifiers
systemd-importd (8)  - VM and container image import and export service
systemd-importd.service (8) - VM and container image import and export service
systemd-inhibit (1)  - Execute a program with an inhibition lock taken
systemd-initctl (8)  - /dev/initctl compatibility
systemd-initctl.service (8) - /dev/initctl compatibility
systemd-initctl.socket (8) - /dev/initctl compatibility
systemd-integritysetup (8) - Disk integrity protection logic
systemd-integritysetup-generator (8) - Unit generator for integrity protected block devices
systemd-integritysetup@.service (8) - Disk integrity protection logic
systemd-journald (8) - Journal service
systemd-journald-audit.socket (8) - Journal service
systemd-journald-dev-log.socket (8) - Journal service
systemd-journald-varlink@.socket (8) - Journal service
systemd-journald.service (8) - Journal service
systemd-journald.socket (8) - Journal service
systemd-journald@.service (8) - Journal service
systemd-journald@.socket (8) - Journal service
systemd-kexec.service (8) - System shutdown logic
systemd-localed (8)  - Locale bus mechanism
systemd-localed.service (8) - Locale bus mechanism
systemd-logind (8)   - Login manager
systemd-logind.service (8) - Login manager
systemd-machine-id-commit.service (8) - Commit a transient machine ID to disk
systemd-machine-id-setup (1) - Initialize the machine ID in /etc/machine-id
systemd-machined (8) - Virtual machine and container registration manager
systemd-machined.service (8) - Virtual machine and container registration manager
systemd-makefs (8)   - Creating and growing file systems on demand
systemd-makefs@.service (8) - Creating and growing file systems on demand
systemd-mkswap@.service (8) - Creating and growing file systems on demand
systemd-modules-load (8) - Load kernel modules at boot
systemd-modules-load.service (8) - Load kernel modules at boot
systemd-mount (1)    - Establish and destroy transient mount or auto-mount points
systemd-network-generator (8) - Generate network configuration from the kernel command line
systemd-network-generator.service (8) - Generate network configuration from the kernel command line
systemd-networkd (8) - Network manager
systemd-networkd-wait-online (8) - Wait for network to come online
systemd-networkd-wait-online.service (8) - Wait for network to come online
systemd-networkd-wait-online@.service (8) - Wait for network to come online
systemd-networkd.service (8) - Network manager
systemd-notify (1)   - Notify service manager about start-up completion and other daemon status ...
systemd-nspawn (1)   - Spawn a command or OS in a light-weight container
systemd-oomd (8)     - A userspace out-of-memory (OOM) killer
systemd-oomd.service (8) - A userspace out-of-memory (OOM) killer
systemd-path (1)     - List and query system and user paths
systemd-portabled (8) - Portable service manager
systemd-portabled.service (8) - Portable service manager
systemd-poweroff.service (8) - System shutdown logic
systemd-pstore (8)   - A service to archive contents of pstore
systemd-pstore.service (8) - A service to archive contents of pstore
systemd-quotacheck (8) - File system quota checker logic
systemd-quotacheck.service (8) - File system quota checker logic
systemd-random-seed (8) - Load and save the system random seed at boot and shutdown
systemd-random-seed.service (8) - Load and save the system random seed at boot and shutdown
systemd-rc-local-generator (8) - Compatibility generator and service to start /etc/rc.local duri...
systemd-reboot.service (8) - System shutdown logic
systemd-remount-fs (8) - Remount root and kernel file systems
systemd-remount-fs.service (8) - Remount root and kernel file systems
systemd-repart (8)   - Automatically grow and add partitions
systemd-repart.service (8) - Automatically grow and add partitions
systemd-resolved (8) - Network Name Resolution manager
systemd-resolved.service (8) - Network Name Resolution manager
systemd-rfkill (8)   - Load and save the RF kill switch state at boot and change
systemd-rfkill.service (8) - Load and save the RF kill switch state at boot and change
systemd-rfkill.socket (8) - Load and save the RF kill switch state at boot and change
systemd-run (1)      - Run programs in transient scope units, service units, or path-, socket-, ...
systemd-run-generator (8) - Generator for invoking commands specified on the kernel command line...
systemd-shutdown (8) - System shutdown logic
systemd-sleep (8)    - System sleep state logic
systemd-sleep.conf (5) - Suspend and hibernation configuration file
systemd-socket-activate (1) - Test socket activation of daemons
systemd-socket-proxyd (8) - Bidirectionally proxy local sockets to another (possibly remote) socket
systemd-stdio-bridge (1) - D-Bus proxy
systemd-stub (7)     - A simple UEFI kernel boot stub
systemd-suspend-then-hibernate.service (8) - System sleep state logic
systemd-suspend.service (8) - System sleep state logic
systemd-sysctl (8)   - Configure kernel parameters at boot
systemd-sysctl.service (8) - Configure kernel parameters at boot
systemd-sysext (8)   - Activates System Extension Images
systemd-sysext.service (8) - Activates System Extension Images
systemd-system-update-generator (8) - Generator for redirecting boot to offline update mode
systemd-system.conf (5) - System and session service manager configuration files
systemd-sysusers (8) - Allocate system users and groups
systemd-sysusers.service (8) - Allocate system users and groups
systemd-sysv-generator (8) - Unit generator for SysV init scripts
systemd-time-wait-sync (8) - Wait until kernel time is synchronized
systemd-time-wait-sync.service (8) - Wait until kernel time is synchronized
systemd-timedated (8) - Time and date bus mechanism
systemd-timedated.service (8) - Time and date bus mechanism
systemd-timesyncd (8) - Network Time Synchronization
systemd-timesyncd.service (8) - Network Time Synchronization
systemd-tmpfiles (8) - Creates, deletes and cleans up volatile and temporary files and directories
systemd-tmpfiles-clean.service (8) - Creates, deletes and cleans up volatile and temporary files...
systemd-tmpfiles-clean.timer (8) - Creates, deletes and cleans up volatile and temporary files a...
systemd-tmpfiles-setup-dev.service (8) - Creates, deletes and cleans up volatile and temporary f...
systemd-tmpfiles-setup.service (8) - Creates, deletes and cleans up volatile and temporary files...
systemd-tty-ask-password-agent (1) - List or process pending systemd password requests
systemd-udev-settle.service (8) - Wait for all pending udev events to be handled
systemd-udevd (8)    - Device event managing daemon
systemd-udevd-control.socket (8) - Device event managing daemon
systemd-udevd-kernel.socket (8) - Device event managing daemon
systemd-udevd.service (8) - Device event managing daemon
systemd-umount (1)   - Establish and destroy transient mount or auto-mount points
systemd-update-utmp (8) - Write audit and utmp updates at bootup, runlevel changes and shutdown
systemd-update-utmp-runlevel.service (8) - Write audit and utmp updates at bootup, runlevel chan...
systemd-update-utmp.service (8) - Write audit and utmp updates at bootup, runlevel changes and s...
systemd-user-runtime-dir (5) - System units to start the user manager
systemd-user-sessions (8) - Permit user logins after boot, prohibit user logins at shutdown
systemd-user-sessions.service (8) - Permit user logins after boot, prohibit user logins at shutdown
systemd-user.conf (5) - System and session service manager configuration files
systemd-veritysetup (8) - Disk verity protection logic
systemd-veritysetup-generator (8) - Unit generator for verity protected block devices
systemd-veritysetup@.service (8) - Disk verity protection logic
systemd-volatile-root (8) - Make the root file system volatile
systemd-volatile-root.service (8) - Make the root file system volatile
systemd-xdg-autostart-generator (8) - User unit generator for XDG autostart files
systemd.automount (5) - Automount unit configuration
systemd.device (5)   - Device unit configuration
systemd.directives (7) - Index of configuration directives
systemd.dnssd (5)    - DNS-SD configuration
systemd.environment-generator (7) - systemd environment file generators
systemd.exec (5)     - Execution environment configuration
systemd.generator (7) - systemd unit generators
systemd.index (7)    - List all manpages from the systemd project
systemd.journal-fields (7) - Special journal fields
systemd.kill (5)     - Process killing procedure configuration
systemd.link (5)     - Network device configuration
systemd.mount (5)    - Mount unit configuration
systemd.negative (5) - DNSSEC trust anchor configuration files
systemd.net-naming-scheme (7) - Network device naming schemes
systemd.netdev (5)   - Virtual Network Device configuration
systemd.network (5)  - Network configuration
systemd.nspawn (5)   - Container settings
systemd.offline-updates (7) - Implementation of offline updates in systemd
systemd.path (5)     - Path unit configuration
systemd.positive (5) - DNSSEC trust anchor configuration files
systemd.preset (5)   - Service enablement presets
systemd.resource-control (5) - Resource control unit settings
systemd.scope (5)    - Scope unit configuration
systemd.service (5)  - Service unit configuration
systemd.slice (5)    - Slice unit configuration
systemd.socket (5)   - Socket unit configuration
systemd.special (7)  - Special systemd units
systemd.swap (5)     - Swap unit configuration
systemd.syntax (7)   - General syntax of systemd configuration files
systemd.target (5)   - Target unit configuration
systemd.time (7)     - Time and date specifications
systemd.timer (5)    - Timer unit configuration
systemd.unit (5)     - Unit configuration
zfs-mount-generator (8) - generate systemd mount units for ZFS filesystems
