#!/bin/bash
# void-fresh-install.sh — 从零安装 Void Linux (UEFI/GPT, x86_64-glibc)
#
# 本脚本不含任何本机/个人身份信息：没有用户名、没有 SSH 公钥、没有主机名、不记录密码。
# 所有身份数据都由调用方在运行时提供。
# pubkey 可选：给了就能 SSH 密钥登录；没给则没有 SSH 登录，只用本地 console
# 配初始口令（首次登录强制改密）。sshd 恒为「仅公钥 + 禁止 root」。
#
# 用法（在 Void live CD 上）：
#   sudo /var/tmp/void-fresh-install.sh --help
#
#   # 方式 A：公钥单独一个文件（推荐，身份数据与脚本完全分离）
#   scp void-fresh-install.sh id_ed25519.pub anon@<vm>:/var/tmp/
#   sudo /var/tmp/void-fresh-install.sh \
#        --user myuser --pubkey-file /var/tmp/id_ed25519.pub
#
#   # 方式 B：外部配置文件
#   sudo /var/tmp/void-fresh-install.sh --conf /var/tmp/void-install.conf
#
#   # 方式 C：环境变量
#   sudo env VOID_USER=myuser VOID_PUBKEY='ssh-ed25519 AAAA... comment' \
#        /var/tmp/void-fresh-install.sh
#
# 依据: https://docs.voidlinux.org/installation/guides/chroot.html (官方 XBPS/chroot 法)
# 不使用 Nixort/VoidLinux-Guide install.sh —— 该脚本实测有 7 个缺陷。
#
# 已规避的坑（全部端到端实测）:
#   1. 目标 chroot 必须有 /etc/resolv.conf，否则 xbps-install 报 Transient resolver failure
#   2. 所有 xbps-install 带 -y + exec </dev/null，绝不弹 [Y/n]
#   3. 只用 --repo 指定的源：宿主按官方换源法写 /etc/xbps.d，目标 rootdir 也先写自己的
#      /etc/xbps.d 再调用 xbps-install（实测 -R 会「追加」仓库，导致连上别的源）
#   5. 服务链接写 /etc/runit/runsvdir/default/，绝不写 /var/service（悬空 symlink 会穿透到 live 宿主）
#   6. 干净 live CD 的 xbps 是旧版，必须先在宿主 -S / -u xbps 才能处理当前仓库
#   7. 账号策略：root 禁止 SSH 登录且不注入任何公钥；普通用户仅公钥登录，
#      初始口令 v01dl!nux 且首次登录强制修改（passwd -e）。
#      不留任何额外的明文密码记录；预生成 ssh host keys + sshd -t 校验。
#   8. 目标系统装 binutils 提供 /usr/bin/strip，消除 dracut 的 "Could not find 'strip'"
#   9. 把 x11-fonts trigger 临时 stub 掉，装完字体后一次性重建缓存再还原
#      （否则每装一个 X11 字体包都跑一遍 fc-cache，实测重复 46 次）
#
# 不重启。除「首次登录必须改掉的初始口令」外不保存任何密码。默认写日志到 /var/log/void-fresh-install.log（root:600），
#   并复制一份到目标系统 /root/void-fresh-install.log，方便事后查看。
#   10. 配置 serial console（GRUB console=ttyS0 + agetty-ttyS0），保证 virsh console 可用
#   11. 不启用 elogind/dhcpcd 服务（dbus 按需拉起 elogind；NetworkManager 负责 DHCP）
#   12. 字体缓存：base-system 之前就占位 stub，之后重写 + fc-cache 兜底，最终只重建一次
#   13. sshd：PermitRootLogin no / PasswordAuthentication no / AuthenticationMethods publickey

set -Eeuo pipefail
exec </dev/null # 保证绝不阻塞在任何交互式提示

# ---------- 默认值：全部是中性技术参数，不含任何身份信息 ----------
DISK=/dev/vda
MNT=/mnt/void-fresh
REPO=https://mirrors.tuna.tsinghua.edu.cn/voidlinux/current # 可用 --repo 覆盖
ARCH=x86_64
ESP_SIZE=512M
TIMEZONE=UTC        # 上游中性默认；可用 --timezone 覆盖
LOCALE=en_US.UTF-8  # Void glibc 默认；可用 --locale 覆盖
HOSTNAME_VALUE=void # 中性默认；可用 --hostname 覆盖
FONTS_TRIGGER=/usr/libexec/xbps-triggers/x11-fonts
LOGFILE=/var/log/void-fresh-install.log
# 普通用户的初始口令：仅用于首次登录时修改（chage -d 0 / passwd -e），
# SSH 只允许公钥认证，root 不允许登录。可用 --initial-password 覆盖。
INITIAL_PASSWORD=${VOID_INITIAL_PASSWORD:-v01dl!nux}

# 身份字段：故意没有默认值，必须由调用方提供
VOID_USER=${VOID_USER:-}
VOID_PUBKEY=${VOID_PUBKEY:-}
VOID_PUBKEY_FILE=${VOID_PUBKEY_FILE:-}
VOID_GECOS=${VOID_GECOS:-}
VOID_SSH_USERS=${VOID_SSH_USERS:-} # 默认仅新用户；root 永不注入公钥
VOID_REPO=${VOID_REPO:-}

die() {
  # tee 进程替换在快速失败时可能丢缓冲：同步写日志 + 直接写原始终端
  printf '\n[FATAL] %s\n' "$*" >&2
  printf '[FATAL-sync] %s\n' "$*" >>"$LOGFILE" 2>/dev/null || true
  { printf '\n[FATAL] %s\n' "$*" >/dev/tty; } 2>/dev/null || true
  sleep 0.3 2>/dev/null || true
  exit 1
}
log() { printf '\n>>> %s\n' "$*"; }

usage() {
  cat <<'EOF'
Usage: void-fresh-install.sh [OPTIONS]

Required identity:
  --user NAME              primary account to create (e.g. alice)
Optional (needed only if you want SSH key login):
  --pubkey-file FILE       file containing ONE ssh public key
     or --pubkey 'KEY'     literal public key string
  If omitted: no SSH login; use local console with the initial password.
     or --conf FILE        shell-style config setting VOID_USER / VOID_PUBKEY(_FILE) / ...
  Environment equivalents: VOID_USER, VOID_PUBKEY, VOID_PUBKEY_FILE, VOID_SSH_USERS

Optional:
  --conf FILE              load shell-style config (VOID_*, DISK, REPO, TIMEZONE, ...)
  --hostname NAME          default: void
  --timezone TZ            default: UTC
  --locale LOCALE          default: en_US.UTF-8
  --disk DEV               default: /dev/vda
  --repo URL               default: https://mirrors.tuna.tsinghua.edu.cn/voidlinux/current
  --esp-size SIZE          default: 512M
  --gecos TEXT             display name for the new user (default: same as --user)
  --initial-password PW    initial password for the new user (default: v01dl!nux)
                           FORCED to be changed at first login (passwd -e)
  --ssh-users LIST         accounts receiving the pubkey
                           default: ONLY the new user (root is NOT included)
  --log-file FILE          default: /var/log/void-fresh-install.log (root:600)
  --help                   show this help

Example config file (/var/tmp/void-install.conf):
  VOID_USER=alice
  VOID_PUBKEY_FILE=/path/to/publickey.pub
  VOID_HOSTNAME=example-host
  VOID_TIMEZONE=UTC
EOF
}

# ---------- 参数解析 ----------
while (($#)); do
  case "$1" in
  --user)
    [[ $# -ge 2 ]] || die "--user 缺参数"
    VOID_USER="$2"
    shift 2
    ;;
  --pubkey)
    [[ $# -ge 2 ]] || die "--pubkey 缺参数"
    VOID_PUBKEY="$2"
    shift 2
    ;;
  --pubkey-file)
    [[ $# -ge 2 ]] || die "--pubkey-file 缺参数"
    VOID_PUBKEY_FILE="$2"
    shift 2
    ;;
  --conf)
    [[ $# -ge 2 ]] || die "--conf 缺参数"
    CONF_FILE="$2"
    shift 2
    ;;
  --hostname)
    [[ $# -ge 2 ]] || die "--hostname 缺参数"
    HOSTNAME_VALUE="$2"
    shift 2
    ;;
  --timezone)
    [[ $# -ge 2 ]] || die "--timezone 缺参数"
    TIMEZONE="$2"
    shift 2
    ;;
  --locale)
    [[ $# -ge 2 ]] || die "--locale 缺参数"
    LOCALE="$2"
    shift 2
    ;;
  --disk)
    [[ $# -ge 2 ]] || die "--disk 缺参数"
    DISK="$2"
    shift 2
    ;;
  --repo)
    [[ $# -ge 2 ]] || die "--repo 缺参数"
    REPO="$2"
    shift 2
    ;;
  --esp-size)
    [[ $# -ge 2 ]] || die "--esp-size 缺参数"
    ESP_SIZE="$2"
    shift 2
    ;;
  --gecos)
    [[ $# -ge 2 ]] || die "--gecos 缺参数"
    VOID_GECOS="$2"
    shift 2
    ;;
  --initial-password)
    [[ $# -ge 2 ]] || die "--initial-password 缺参数"
    INITIAL_PASSWORD="$2"
    shift 2
    ;;
  --log-file)
    [[ $# -ge 2 ]] || die "--log-file 缺参数"
    LOGFILE="$2"
    shift 2
    ;;
  --ssh-users)
    [[ $# -ge 2 ]] || die "--ssh-users 缺参数"
    VOID_SSH_USERS="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *) die "未知参数: $1（用 --help 查看用法）" ;;
  esac
done

# 配置文件最后加载，可覆盖上面的值；命令行优先的场景由调用方自行排序
if [[ -n "${CONF_FILE:-}" ]]; then
  [[ -r "$CONF_FILE" ]] || die "无法读取配置文件: $CONF_FILE"
  # shellcheck disable=SC1090
  source "$CONF_FILE"
  # 配置文件允许用 VOID_HOSTNAME / VOID_TIMEZONE / ... 形式
  HOSTNAME_VALUE="${VOID_HOSTNAME:-$HOSTNAME_VALUE}"
  TIMEZONE="${VOID_TIMEZONE:-$TIMEZONE}"
  LOCALE="${VOID_LOCALE:-$LOCALE}"
  DISK="${VOID_DISK:-$DISK}"
  REPO="${VOID_REPO:-$REPO}"
  ESP_SIZE="${VOID_ESP_SIZE:-$ESP_SIZE}"
  INITIAL_PASSWORD="${VOID_INITIAL_PASSWORD:-$INITIAL_PASSWORD}"
fi

# ---------- 默认日志：控制台 + 文件（含 EXIT trap 输出） ----------
mkdir -p "$(dirname "$LOGFILE")" 2>/dev/null || true
: >"$LOGFILE"
chmod 600 "$LOGFILE" 2>/dev/null || true
printf '===== void-fresh-install 开始 %s =====\n' "$(date -u +%FT%TZ)" >>"$LOGFILE"
printf '  命令: %s %s\n' "$0" "$*" >>"$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1

# ---------- 身份输入校验（严格，绝不使用任何内置身份） ----------
[[ -n "$VOID_USER" ]] || {
  usage >&2
  die "必须提供 --user / VOID_USER"
}
[[ "$VOID_USER" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]] || die "用户名不合法: $VOID_USER"
[[ "$VOID_USER" != root ]] || die "--user 不能是 root"
# pubkey 可选。sshd 恒为「仅公钥 + 禁止 root」：
#   给了公钥 -> 可以 SSH 密钥登录（host 远程驱动场景）
#   没给公钥 -> 没有任何 authorized_keys，SSH 无法登录；
#               本地 USB live CD 重启后用 console + 初始口令登录即可。
if [[ -z "$VOID_PUBKEY" && -n "$VOID_PUBKEY_FILE" ]]; then
  [[ -r "$VOID_PUBKEY_FILE" ]] || die "公钥文件不可读: $VOID_PUBKEY_FILE"
  VOID_PUBKEY=$(head -n1 "$VOID_PUBKEY_FILE")
fi
if [[ -n "$VOID_PUBKEY" ]]; then
  [[ "$VOID_PUBKEY" =~ ^(ssh-(rsa|ed25519)|ecdsa-sha2-|sk-ssh-|sk-ecdsa-) ]] ||
    die "公钥格式不合法（应以 ssh-ed25519 / ssh-rsa / ecdsa-sha2- 开头）"
  [[ "$VOID_PUBKEY" != *"'"* ]] || die "公钥注释里不能含单引号"
  HAS_PUBKEY=1
else
  HAS_PUBKEY=0
  log "未提供公钥 -> 无 SSH 登录；装完用本地 console + 初始口令登录（首次登录强制改密）"
fi
VOID_GECOS="${VOID_GECOS:-$VOID_USER}"
[[ -n "$VOID_SSH_USERS" ]] || VOID_SSH_USERS="$VOID_USER"
HOSTNAME_VALUE="${HOSTNAME_VALUE:-void}"
[[ "$HOSTNAME_VALUE" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]] || die "主机名不合法"
[[ -f "/usr/share/zoneinfo/$TIMEZONE" ]] || die "时区不存在: $TIMEZONE"
[[ "$REPO" =~ ^https:// ]] || die "仓库必须是 https URL"

ESP="${DISK}1"
ROOT="${DISK}2"

# ---------- trap: 无论成功失败都卸载、还原 trigger ----------
cleanup() {
  local rc=$?
  if [[ -f /var/tmp/x11-fonts.orig ]]; then
    cp -a /var/tmp/x11-fonts.orig "$MNT$FONTS_TRIGGER" 2>/dev/null || true
    # 若中途失败，别把 stub 的 fc-cache 留在装出来的系统里
    if [[ -x "$MNT/usr/bin/fc-cache.real" ]]; then
      mv -f "$MNT/usr/bin/fc-cache.real" "$MNT/usr/bin/fc-cache" 2>/dev/null || true
    fi
    rm -f /var/tmp/x11-fonts.orig
  fi
  if findmnt -rn -o TARGET | grep -qx "$MNT"; then
    umount -R "$MNT" 2>/dev/null || true
  fi
  rmdir "$MNT" 2>/dev/null || true
  if ((rc != 0)); then printf '\n[ABORTED rc=%d] 日志: %s\n' "$rc" "$LOGFILE" >&2; fi
  sleep 0.5 2>/dev/null || true
  printf '===== void-fresh-install 结束 rc=%d %s =====\n' "$rc" "$(date -u +%FT%TZ)" >>"$LOGFILE" 2>/dev/null || true
  exit "$rc"
}
trap cleanup EXIT INT TERM

# ---------- 0. 前置检查 + 干净 live CD 自举 ----------
log "0) 前置检查 / live CD 自举"
[ "$(id -u)" = 0 ] || die "必须 root（用 sudo 运行）"
[ -b "$DISK" ] || die "$DISK 不是块设备"
[ -d /sys/firmware/efi ] || die "不是 UEFI 启动"
[ "$(cat /sys/firmware/efi/fw_platform_size)" = 64 ] || die "不是 64-bit UEFI"
for c in sfdisk wipefs mkfs.vfat mkfs.ext4 blkid mount umount xbps-install xbps-query \
  chroot useradd ssh-keygen sshd grub-install grub-mkconfig \
  xbps-reconfigure udevadm install awk grep sed findmnt head; do
  command -v "$c" >/dev/null || die "缺命令: $c"
done
findmnt -rn -o SOURCE | grep -q "^$DISK" && die "$DISK 已挂载" || true
sfdisk -d "$DISK" >/dev/null 2>&1 && log "注意: $DISK 已有分区表，将全部抹掉" || true

log "0a) 把 live 宿主切到 $REPO（官方换源法：/etc/xbps.d 覆盖 /usr/share/xbps.d）"
mkdir -p /etc/xbps.d
cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/
sed -i -E "s|^repository=.*|repository=$REPO|" /etc/xbps.d/*-repository-*.conf
# 干净 live CD 的 xbps 是旧版（本 ISO 为 0.59.2_3），同步当前仓库后会强制自更新
xbps-install -S -y
xbps-install -y -u xbps
log "    xbps: $(xbps-install --version)"
grep -h '^repository' /etc/xbps.d/*-repository-*.conf

# ---------- 1. 分区 ----------
log "1) GPT 分区 + 格式化"
wipefs -a "$DISK" >/dev/null 2>&1 || true
sfdisk --wipe always "$DISK" <<EOF
label: gpt
size=$ESP_SIZE, type=U, name="EFI"
type=L, name="ROOT"
EOF
udevadm settle || true
for i in 1 2; do
  for _ in $(seq 1 20); do
    [ -b "$DISK$i" ] && break
    sleep 0.25
  done
  [ -b "$DISK$i" ] || die "分区 $DISK$i 未出现"
done
mkfs.vfat -F32 "$ESP"
mkfs.ext4 -F "$ROOT"
sfdisk -d "$DISK"

# ---------- 2. 挂载 ----------
log "2) 挂载"
mkdir -p "$MNT"
mount "$ROOT" "$MNT"
mkdir -p "$MNT/boot/efi"
mount "$ESP" "$MNT/boot/efi"

# ---------- 3. RSA keys + base-system ----------
log "3) 安装 base-system（源: $REPO）"
mkdir -p "$MNT/var/db/xbps/keys" "$MNT/etc/xbps.d"
cp -a /var/db/xbps/keys/. "$MNT/var/db/xbps/keys/"
printf 'repository=%s\n' "$REPO" >"$MNT/etc/xbps.d/00-repository-main.conf"
# 目标 rootdir 已有自己的 conf -> 不带 -R，避免追加别的源
# 字体缓存抑制必须在【任何】xbps 解包之前：base-system 阶段也会装 X11 字体并
# 触发 x11-fonts。先在空 rootfs 里建占位 trigger，装完后立刻重写一次。
mkdir -p "$MNT/usr/libexec/xbps-triggers" "$MNT/usr/bin"
printf '#!/bin/sh\nexit 0\n' >"$MNT$FONTS_TRIGGER"
chmod 755 "$MNT$FONTS_TRIGGER"

env XBPS_ARCH="$ARCH" xbps-install -S -y -r "$MNT" base-system

log "3b) 抑制 x11-fonts / fc-cache 重复触发（装完后一次性重建）"
# base-system 已把真正的 trigger 装进来了 -> 此时才备份原件，再覆盖成 stub
[[ -f "$MNT$FONTS_TRIGGER" ]] || die "目标系统缺少 $FONTS_TRIGGER"
cp -a "$MNT$FONTS_TRIGGER" /var/tmp/x11-fonts.orig
printf '#!/bin/sh\nexit 0\n' >"$MNT$FONTS_TRIGGER"
chmod 755 "$MNT$FONTS_TRIGGER"
if [[ -x "$MNT/usr/bin/fc-cache" && ! -e "$MNT/usr/bin/fc-cache.real" ]]; then
  mv "$MNT/usr/bin/fc-cache" "$MNT/usr/bin/fc-cache.real"
  printf '#!/bin/sh\nexit 0\n' >"$MNT/usr/bin/fc-cache"
  chmod 755 "$MNT/usr/bin/fc-cache"
fi

# ---------- 4. 目标系统源 / DNS / 基础配置 ----------
log "4) 写入目标系统仓库源与 DNS"
[[ "$(grep -h '^repository' "$MNT/etc/xbps.d/00-repository-main.conf")" = "repository=$REPO" ]] ||
  die "目标仓库源写入异常"
cp /etc/resolv.conf "$MNT/etc/resolv.conf"
[[ -f "$MNT/etc/hosts" ]] || cp /etc/hosts "$MNT/etc/hosts"
printf '%s\n' "$HOSTNAME_VALUE" >"$MNT/etc/hostname"
printf 'LANG=%s\n' "$LOCALE" >"$MNT/etc/locale.conf"
ln -sf "/usr/share/zoneinfo/$TIMEZONE" "$MNT/etc/localtime"
if [[ -f "$MNT/etc/default/libc-locales" ]]; then
  sed -i -E "s/^#(${LOCALE}[[:space:]])/\1/" "$MNT/etc/default/libc-locales"
fi
ROOT_UUID=$(blkid -s UUID -o value "$ROOT")
ESP_UUID=$(blkid -s UUID -o value "$ESP")
cat >"$MNT/etc/fstab" <<EOF
UUID=$ROOT_UUID / ext4 defaults 0 1
UUID=$ESP_UUID /boot/efi vfat defaults 0 2
tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0
EOF

# ---------- 5. 挂载 chroot API（含 efivarfs） ----------
log "5) 挂载 chroot API"
mkdir -p "$MNT"/{dev,proc,sys,run}
mount --rbind /dev "$MNT/dev"
mount --make-rslave "$MNT/dev"
mount -t proc proc "$MNT/proc"
mount --rbind /sys "$MNT/sys"
mount --make-rslave "$MNT/sys"
mount --rbind /run "$MNT/run"
mount --make-rslave "$MNT/run"
mkdir -p "$MNT/sys/firmware/efi/efivars"
mount -t efivarfs none "$MNT/sys/firmware/efi/efivars" 2>/dev/null || true

# ---------- 6. chroot 内装桌面/网络/GRUB ----------
log "6) chroot 内安装额外包（全部 -y，无交互）"
# binutils 也装进目标：以后内核升级跑 dracut 时才有 strip
PKGS="sudo xtools dbus pipewire wireplumber NetworkManager openssh elogind polkit \
      vim xorg xfce4 lightdm lightdm-gtk-greeter grub-x86_64-efi efibootmgr fastfetch binutils"
chroot "$MNT" /bin/sh -c "xbps-install -S -y -u $PKGS"
chroot "$MNT" /bin/sh -c "xbps-reconfigure -f glibc-locales"

# 6b) 字体 stub 保持到 step 9 之后：xbps-reconfigure -fa 会重跑所有
#     包的 INSTALL 脚本并再次触发 x11-fonts，过早还原会前功尽弃。
#     单次重建统一放到 step 9 末尾（见 "9b"）。

# ---------- 7. 账号 / SSH 公钥 / 口令策略 ----------
log "7) 创建用户 $VOID_USER + 可选注入公钥 + 设置首次登录改密"
chroot "$MNT" /bin/sh -c \
  "id -u '$VOID_USER' >/dev/null 2>&1 || useradd -m -G wheel,users,audio,video,network -s /bin/bash -c '$VOID_GECOS' '$VOID_USER'"
printf '%%wheel ALL=(ALL) ALL\n' >"$MNT/etc/sudoers.d/10-wheel"
chmod 0440 "$MNT/etc/sudoers.d/10-wheel"

# 初始口令（仅用于首次登录时被要求修改；SSH 本身不允许口令认证）
printf '%s:%s\n' "$VOID_USER" "$INITIAL_PASSWORD" | chroot "$MNT" chpasswd -c SHA512
# 强制首次登录改口令：公钥认证成功后，PAM account 阶段会提示
# "You are required to change your password immediately"，先要求输入【当前口令
# = 初始口令】再设新口令。这是仅公钥 + 首次改密的正常交互（不是被锁在外面）。
chroot "$MNT" passwd -e "$VOID_USER" >/dev/null 2>&1 || \
  chroot "$MNT" chage -d 0 "$VOID_USER" >/dev/null 2>&1 || die "无法设置首次登录改密"
log "    初始口令已设置。首次登录（SSH 公钥或本地 console）都会被要求改密"

# 公钥只写 --ssh-users 指定的账号，且【强制拒绝 root】
if [[ "$HAS_PUBKEY" -eq 1 ]]; then
IFS=',' read -ra _ssh_users <<<"$VOID_SSH_USERS"
for u in "${_ssh_users[@]}"; do
  u=$(printf '%s' "$u" | tr -d '[:space:]')
  [[ -n "$u" ]] || continue
  if [[ "$u" = root ]]; then
    printf '  [deny] 拒绝把公钥写入 root 的 authorized_keys（root 禁止 SSH 登录）\n'
    continue
  fi
  h="/home/$u"
  [[ -d "$MNT$h" ]] || die "账号 $u 的主目录不存在（只能用已存在的账号）"
  mkdir -p "$MNT$h/.ssh"
  printf '%s\n' "$VOID_PUBKEY" >"$MNT$h/.ssh/authorized_keys"
  chmod 700 "$MNT$h/.ssh"
  chmod 600 "$MNT$h/.ssh/authorized_keys"
  chroot "$MNT" /bin/sh -c "chown -R \"\$(id -u '$u'):\$(id -g '$u')\" '$h/.ssh'"
  printf '  [key] %s -> %s/.ssh/authorized_keys\n' "$u" "$h"
done
fi

# 确保 root 没有任何 authorized_keys / .ssh/rc 提示残留
rm -f "$MNT/root/.ssh/authorized_keys" "$MNT/root/.ssh/rc" 2>/dev/null || true
rmdir "$MNT/root/.ssh" 2>/dev/null || true

# ---- sshd：恒定「仅公钥 + 禁止 root」，与是否提供公钥无关 ----
# 没提供公钥时目标系统没有任何 authorized_keys，因此 SSH 无法登录；
# 本地 USB live CD 场景本来就用 console，不需要也不应该放开密码认证。
mkdir -p "$MNT/etc/ssh/sshd_config.d"
cat >"$MNT/etc/ssh/sshd_config.d/10-hardening.conf" <<'SSHDCFG'
# 由 void-fresh-install.sh 生成：仅公钥登录
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
AuthenticationMethods publickey
PermitEmptyPasswords no
UsePAM yes
SSHDCFG
chmod 644 "$MNT/etc/ssh/sshd_config.d/10-hardening.conf"
# OpenSSH 的 Include 位于主配置靠前处（本镜像第 16 行，先于任何设置项），
# 因此 drop-in 会优先生效；若镜像版本没有 Include，则补一行到最前面。
grep -qE '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config.d/' "$MNT/etc/ssh/sshd_config" || {
  sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' "$MNT/etc/ssh/sshd_config"; }

# 预生成 host keys + 校验配置（这一步必须过，否则装出来登不进）
chroot "$MNT" ssh-keygen -A >/dev/null 2>&1 || true
chroot "$MNT" /usr/bin/sshd -t || die "sshd -t 校验失败"
log "    sshd -t OK：仅公钥 / 禁止 root（无公钥时无 SSH 登录，走 console）"

# ---------- 8. 服务：写 /etc/runit/runsvdir/default/ ----------
log "8) 启用服务"
mkdir -p "$MNT/etc/runit/runsvdir/default"
[[ -e "$MNT/etc/runit/runsvdir/current" ]] || ln -s default "$MNT/etc/runit/runsvdir/current"
# 不启用 elogind：dbus 会按需拉起；两者同开每秒报 "already running" 并重启（串口刷屏）
# dhcpcd 保留启用（与 NM 并存时由 NM 的 internal DHCP 后端统一管理）；
# 显式写 dhcp=internal，避免不同 NM 版本默认后端变化导致重启后拿不到 IP。
mkdir -p "$MNT/etc/NetworkManager/conf.d"
printf '[main]\ndhcp=internal\n' >"$MNT/etc/NetworkManager/conf.d/10-dhcp-internal.conf"
for s in dbus polkitd NetworkManager dhcpcd sshd lightdm agetty-ttyS0; do
  [[ -d "$MNT/etc/sv/$s" ]] || {
    printf '  [skip] %s (无服务定义)\n' "$s"
    continue
  }
  ln -sf "/etc/sv/$s" "$MNT/etc/runit/runsvdir/default/$s"
  printf '  [on] %s\n' "$s"
done

# ---------- 9. GRUB (UEFI) ----------
log "9) 安装 GRUB + 生成 initramfs/grub.cfg"
chroot "$MNT" /bin/sh -c 'grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Void' ||
  chroot "$MNT" /bin/sh -c 'grub-install --no-nvram --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Void'
chroot "$MNT" /bin/sh -c 'xbps-reconfigure -fa'
# serial console：内核消息与 GRUB 菜单都走 ttyS0，配合 agetty-ttyS0
cat >"$MNT/etc/default/grub" <<'GRUBCFG'
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="Void"
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=4 console=ttyS0,115200 console=tty0"
GRUB_TERMINAL_INPUT="console serial"
GRUB_TERMINAL_OUTPUT="console serial"
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
GRUBCFG
chroot "$MNT" /bin/sh -c 'grub-mkconfig -o /boot/grub/grub.cfg'

# ---------- 9b. xbps-reconfigure -fa 之后：唯一一次字体缓存重建 ----------
log "9b) 唯一一次重建 X11 字体索引 + fontconfig 缓存"
if [[ -x "$MNT/usr/bin/fc-cache.real" ]]; then
  mv -f "$MNT/usr/bin/fc-cache.real" "$MNT/usr/bin/fc-cache"
fi
printf '  [font] 单次重建开始 %s\n' "$(date -u +%FT%TZ)"
chroot "$MNT" /bin/sh -c '
  set -e
  for d in /usr/share/fonts/X11/*/ /usr/share/fonts/X11/*/*/; do
    [ -d "$d" ] || continue
    if ls "$d"*.pcf* "$d"*.ttf "$d"*.otf "$d"*.pfa "$d"*.pfb >/dev/null 2>&1; then
      mkfontdir   "$d" 2>/dev/null || true
      mkfontscale "$d" 2>/dev/null || true
    fi
  done
  fc-cache -f
'
printf '  [font] 单次重建结束 %s\n' "$(date -u +%FT%TZ)"
cp -a /var/tmp/x11-fonts.orig "$MNT$FONTS_TRIGGER"
rm -f /var/tmp/x11-fonts.orig
log "    x11-fonts trigger 与 fc-cache 已还原"


# ---------- 10. 验收 ----------
log "10) 验收"
printf '  包数: '
xbps-query -r "$MNT" -l | wc -l
printf '  源:   '
grep -h '^repository' "$MNT/etc/xbps.d/"*.conf
printf '  密码: 仅设初始口令并强制首次登录修改（SSH 仅公钥）\n'
printf '  authorized_keys: '
find "$MNT/root/.ssh" "$MNT/home" -name authorized_keys -printf '%p ' 2>/dev/null || true
echo
printf '  SSH host keys: '
(ls "$MNT/etc/ssh/" | grep -c ssh_host_) || true
printf '  服务: '
ls "$MNT/etc/runit/runsvdir/default/" | tr '\n' ' '
echo
printf '  strip: '
(ls -la "$MNT/usr/bin/strip" 2>/dev/null | awk '{print $NF}') || true
printf '  EFI:  '
find "$MNT/boot/efi" -name 'grubx64.efi' -printf '%p\n'
printf '  grub 条目: '
(grep -c menuentry "$MNT/boot/grub/grub.cfg") || true
printf '  sshd 有效配置: '
chroot "$MNT" /usr/bin/sshd -T 2>/dev/null | grep -iE '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|authenticationmethods)' | tr '\n' ' '
echo
printf '  root authorized_keys: '
[ -e "$MNT/root/.ssh/authorized_keys" ] && echo '存在(错误!)' || echo '不存在 ✅'
printf '  dhcp=internal: '
grep -h 'dhcp=' "$MNT/etc/NetworkManager/conf.d/"*.conf 2>/dev/null || echo '(未写)' 

mkdir -p "$MNT/root"
cp "$LOGFILE" "$MNT/root/void-fresh-install.log" 2>/dev/null || true
chmod 600 "$MNT/root/void-fresh-install.log" 2>/dev/null || true
log "安装完成。root 禁止 SSH 且无 authorized_keys；sshd 仅公钥。"
log "有公钥=可 SSH 密钥登录；无公钥=走本地 console。两种都需首次登录改初始口令。"
log "virsh console 可用；未保存任何额外明文密码。没有重启。"
log "日志: $LOGFILE （目标系统内也存一份 /root/void-fresh-install.log）"
