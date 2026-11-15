#!/bin/sh
# void-bootstrap.sh — 在 Void live CD 里通过 curl|sh 一键取回安装器
#
# Void 官方 live CD 没有 curl/wget，只有 python3。两条路：
#
# (推荐, 零额外依赖) 用 python3 拉取并执行，不用装任何东西：
#   python3 -c 'import urllib.request as u,subprocess as s;p="/tmp/void-bootstrap.sh";open(p,"wb").write(u.urlopen("https://raw.githubusercontent.com/LeisureLinux/bilibili/master/scripts/void-bootstrap.sh",timeout=60).read());s.run(["sudo","-n","sh",p,"--user","alice"])'
#
# (想要真正的 curl|bash) 先在 live CD 里装 curl。ISO 自带索引是旧快照，
# 默认源下 curl-8.11.1_2.sig2 已 404，必须先换源 + -S；新版 libcurl 又需要
# 升级 libssh2。最短可靠四步（约 2 秒）：
#   sudo mkdir -p /etc/xbps.d
#   sudo cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/
#   sudo sed -i 's|https://repo-default.voidlinux.org|https://mirrors.tuna.tsinghua.edu.cn/voidlinux|g' /etc/xbps.d/*-repository-*.conf
#   sudo xbps-install -Syu curl libssh2
# 然后：
#   curl -fsSL .../void-bootstrap.sh | sudo sh -s -- --user alice
#
# 安全设计：
#   * 本脚本【绝不】自动抹盘。不带 --user 时只下载 installer 并打印用法。
#   * 场景 B（USB 本机 live CD）：curl|sh + --user alice 即可，不需要 pubkey。
#     sshd 仍只认公钥，因此没有 SSH 登录；重启后用 console + 初始口令登录
#     并强制改密。
#   * 场景 A（从 host 远程驱动虚机）：用 void-live-provision.sh --ip <IP>，
#     它会在运行时注入 pubkey，装完即可密钥登录（仅公钥）。
#   * installer 本体保持零本机属性；身份由调用方在运行时提供。
#   * 全程不写任何密码/密钥到仓库，不依赖本机身份。
#
# 需要：python3 或 curl、root（sudo -n 或 root shell）、UEFI live CD。

set -eu

RAW_BASE="https://raw.githubusercontent.com/LeisureLinux/bilibili/master/scripts"
INSTALLER_URL="$RAW_BASE/void-fresh-install.sh"
DEST=${VOID_INSTALLER_DEST:-${TMPDIR:-/tmp}/void-fresh-install.sh}
ANSWER=""

log() { printf '\n>>> %s\n' "$*"; }
die() { printf '\n[FATAL] %s\n' "$*" >&2; exit 1; }

# ---------- 参数（透传给 installer） ----------
ARGS=""
HAS_IDENTITY=0
EXPLICIT_CONFIRM=0
while [ $# -gt 0 ]; do
  case "$1" in
    --user) HAS_IDENTITY=1 ;;   # 单独 --user 就足以触发安装（无 SSH，走 console）
    --help|-h) EXPLICIT_CONFIRM=-1 ;;   # 帮助优先：绝不进入安装分支
    --yes-i-know-this-wipes-the-disk) EXPLICIT_CONFIRM=1; shift; continue ;;
  esac
  # 用 printf %q 不可用（sh），简单地把参数逐个用单引号包起来
  esc=$(printf '%s' "$1" | sed "s/'/'\\\\''/g")
  ARGS="$ARGS '$esc'"
  shift
done
[ "$HAS_IDENTITY" -ge 1 ] && [ "$EXPLICIT_CONFIRM" -ge 0 ] && EXPLICIT_CONFIRM=1
[ "$EXPLICIT_CONFIRM" -lt 0 ] && EXPLICIT_CONFIRM=0

# ---------- 前置检查 ----------
# Void live CD 只有 python3（无 curl/wget）；有 curl 时优先用 curl。
if command -v curl >/dev/null 2>&1; then
  dl() { curl -fsSL --max-time 60 "$1" -o "$2"; }
elif command -v python3 >/dev/null 2>&1; then
  dl() { python3 -c 'import sys,urllib.request,ssl; u,o=sys.argv[1],sys.argv[2]; ctx=ssl.create_default_context(); open(o,"wb").write(urllib.request.urlopen(u,timeout=60,context=ctx).read())' "$1" "$2"; }
else
  die "live CD 既无 curl 也无 python3，无法下载"
fi
[ "$(id -u)" -eq 0 ] || die "请用 root 运行（python3 ... | sudo sh -s -- ...）"
[ -d /sys/firmware/efi ] || die "不是 UEFI 启动"

log "下载 installer -> $DEST"
dl "$INSTALLER_URL" "$DEST" || die "下载失败: $INSTALLER_URL"
chmod 755 "$DEST"
printf '  字节数: %s\n' "$(wc -c <"$DEST")"
bash -n "$DEST" 2>/dev/null || die "下载的文件不是合法 bash 脚本（或下载不完整）"

# ---------- 默认：只展示用法，不安装 ----------
if [ "$EXPLICIT_CONFIRM" -eq 0 ]; then
  log "installer 已就绪（没有执行安装，磁盘未被改动）"
  "$DEST" --help 2>/dev/null | head -40 || true
  cat <<'EOF'

USB 本机 live CD（最简单，重启后走 console）：
  curl -fsSL .../void-bootstrap.sh | sudo sh -s -- --user alice
  # 或用已下载的：<下载目录>/void-fresh-install.sh --user alice
  # 无公钥 -> 无 SSH 登录；console 用初始口令登录并强制改密

从另一台机器远程注入公钥（装完仅公钥登录）：
  curl -fsSL .../void-bootstrap.sh | sudo sh -s -- --user alice --pubkey-file /path/alice.pub
EOF
  exit 0
fi

log "执行安装（目标盘 /dev/vda 将被抹掉）"
eval "'$DEST' $ARGS"
