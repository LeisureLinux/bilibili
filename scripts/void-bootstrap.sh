#!/bin/sh
# void-bootstrap.sh — 在 Void live CD 里通过 curl|sh 一键取回安装器
#
# Void 官方 live CD 没有 curl/wget，只有 python3。用一行 python3 拉取并执行：
#   python3 -c 'import urllib.request as u,subprocess as s;p="/tmp/void-bootstrap.sh";open(p,"wb").write(u.urlopen("https://raw.githubusercontent.com/LeisureLinux/bilibili/master/scripts/void-bootstrap.sh",timeout=60).read());s.run(["sudo","-n","sh",p])'
# 有 curl 的机器上也可以用：
#   curl -fsSL .../void-bootstrap.sh | sh -s -- --user alice --pubkey-file /path/alice.pub
#
# 安全设计：
#   * 本脚本【绝不】自动抹盘。不带参数时只把 installer 下到临时目录并打印用法。
#   * 只有显式给了 --user 和 --pubkey-file/--pubkey（或 --yes-i-know-this-wipes-the-disk）
#     才执行安装，且执行前会再确认一次目标盘。
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
    --user|--pubkey|--pubkey-file) HAS_IDENTITY=$((HAS_IDENTITY+1)) ;;
    --yes-i-know-this-wipes-the-disk) EXPLICIT_CONFIRM=1; shift; continue ;;
  esac
  # 用 printf %q 不可用（sh），简单地把参数逐个用单引号包起来
  esc=$(printf '%s' "$1" | sed "s/'/'\\\\''/g")
  ARGS="$ARGS '$esc'"
  shift
done
[ "$HAS_IDENTITY" -ge 2 ] && EXPLICIT_CONFIRM=1

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

要真正安装（会抹掉 /dev/vda），请显式提供身份参数，例如：

  python3 -c 'import urllib.request as u,subprocess as s;p="/tmp/void-bootstrap.sh";open(p,"wb").write(u.urlopen("https://raw.githubusercontent.com/LeisureLinux/bilibili/master/scripts/void-bootstrap.sh",timeout=60).read());s.run(["sudo","-n","sh",p])' \
       -- --user alice --pubkey-file /path/to/alice.pub

或在已下载的脚本上直接运行：
  <下载目录>/void-fresh-install.sh --user alice --pubkey-file /path/to/alice.pub
EOF
  exit 0
fi

log "执行安装（目标盘 /dev/vda 将被抹掉）"
eval "'$DEST' $ARGS"
