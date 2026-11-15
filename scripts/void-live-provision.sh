#!/bin/bash
# void-live-provision.sh — 从本机 PC 驱动 Void live CD 一键安装
#
# 只在本机 PC 运行。它【在运行时】读取本机身份（用户名 / 公钥 / 时区），
# 通过 live CD 默认账号 anon/voidlinux 把 void-fresh-install.sh 传进去并执行。
# void-fresh-install.sh 本身保持零本机属性；这里也不硬编码任何身份。
#
#   ./void-live-provision.sh --ip <VM-IP>
#   ./void-live-provision.sh --ip <VM-IP> --user bob --pubkey ~/.ssh/bob.pub
#   ./void-live-provision.sh --ip <VM-IP> --timezone UTC --hostname lab
#   ./void-live-provision.sh --ip <VM-IP> --dry-run
#
# live CD 默认口令只在运行时通过 SSH_ASKPASS 传给 ssh，不写进任何文件。
# 不重启虚机；安装完成后 installer 自己打印日志路径。

set -Eeuo pipefail

# ---------- 默认值：中性技术参数 ----------
IP=""
LIVE_USER=anon
LIVE_PASSWORD=voidlinux          # Void 官方 live CD 默认口令（文档公开值）
LIVE_SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
               -o ConnectTimeout=10 -o PreferredAuthentications=password
               -o PubkeyAuthentication=no -o NumberOfPasswordPrompts=1)
# installer 默认就在本脚本同目录（仓库里三个脚本放一起），不硬编码任何本机路径
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
INSTALLER=${INSTALLER:-$SCRIPT_DIR/void-fresh-install.sh}
REMOTE_DIR=${REMOTE_DIR:-/var/tmp}
DRY_RUN=0
KEEP_ASKPASS=0

# 身份字段：运行时从本机推导，或由参数覆盖
OPT_USER=""
OPT_PUBKEY=""
OPT_PUBKEY_FILE=""
OPT_TIMEZONE=""
OPT_HOSTNAME=""
OPT_LOCALE=""
OPT_REPO=""
OPT_DISK=""
OPT_INITIAL_PASSWORD=""
OPT_EXTRA=()

die() { printf '\n[FATAL] %s\n' "$*" >&2; exit 1; }
log() { printf '\n>>> %s\n' "$*"; }

usage() {
  cat <<'EOF'
Usage: void-live-provision.sh --ip ADDRESS [OPTIONS]

Required:
  --ip ADDRESS             live CD 虚机的 IP（唯一必填）

Runtime-injected defaults (read from THIS machine at run time, overrideable):
  --user NAME              default: $(id -un)
  --pubkey-file FILE       default: first existing of
                           ~/.ssh/id_ed25519.pub, id_ecdsa.pub, id_rsa.pub
  --pubkey 'KEY'           literal key (overrides --pubkey-file)
  --timezone TZ            default: from /etc/localtime (e.g. UTC)
  --locale LOCALE          default: from $LANG, else C.UTF-8

Optional passthrough to the installer:
  --hostname NAME          default: void
  --repo URL               default: installer's TUNA mirror
  --disk DEV               default: /dev/vda
  --initial-password PW    default: installer's initial password
  --installer PATH         local path to void-fresh-install.sh
  --live-user NAME         default: anon
  --live-password PW       default: voidlinux
  --extra 'ARGS'           extra raw args appended to installer invocation
  --dry-run                print the plan only; do not connect or modify anything
  -h | --help              show this help

Environment equivalents: VOID_IP, VOID_USER, VOID_PUBKEY_FILE, VOID_PUBKEY,
VOID_TIMEZONE, VOID_LIVE_PASSWORD, VOID_INSTALLER.

Examples:
  void-live-provision.sh --ip <VM-IP>
  void-live-provision.sh --ip <VM-IP> --user alice --timezone UTC --extra '--refresh'
  void-live-provision.sh --ip <VM-IP> --dry-run
EOF
}

# ---------- 参数 ----------
while (($#)); do
  case "$1" in
    --ip)               [[ $# -ge 2 ]] || die "--ip 缺参数"; IP="$2"; shift 2 ;;
    --ip=*)             IP="${1#--ip=}"; shift ;;
    --user)             [[ $# -ge 2 ]] || die "--user 缺参数"; OPT_USER="$2"; shift 2 ;;
    --pubkey-file)      [[ $# -ge 2 ]] || die "--pubkey-file 缺参数"; OPT_PUBKEY_FILE="$2"; shift 2 ;;
    --pubkey)           [[ $# -ge 2 ]] || die "--pubkey 缺参数"; OPT_PUBKEY="$2"; shift 2 ;;
    --timezone)         [[ $# -ge 2 ]] || die "--timezone 缺参数"; OPT_TIMEZONE="$2"; shift 2 ;;
    --locale)           [[ $# -ge 2 ]] || die "--locale 缺参数"; OPT_LOCALE="$2"; shift 2 ;;
    --hostname)         [[ $# -ge 2 ]] || die "--hostname 缺参数"; OPT_HOSTNAME="$2"; shift 2 ;;
    --repo)             [[ $# -ge 2 ]] || die "--repo 缺参数"; OPT_REPO="$2"; shift 2 ;;
    --disk)             [[ $# -ge 2 ]] || die "--disk 缺参数"; OPT_DISK="$2"; shift 2 ;;
    --initial-password) [[ $# -ge 2 ]] || die "--initial-password 缺参数"; OPT_INITIAL_PASSWORD="$2"; shift 2 ;;
    --installer)        [[ $# -ge 2 ]] || die "--installer 缺参数"; INSTALLER="$2"; shift 2 ;;
    --live-user)        [[ $# -ge 2 ]] || die "--live-user 缺参数"; LIVE_USER="$2"; shift 2 ;;
    --live-password)    [[ $# -ge 2 ]] || die "--live-password 缺参数"; LIVE_PASSWORD="$2"; shift 2 ;;
    --extra)            [[ $# -ge 2 ]] || die "--extra 缺参数"; OPT_EXTRA+=("$2"); shift 2 ;;
    --dry-run)          DRY_RUN=1; shift ;;
    -h|--help)          usage; exit 0 ;;
    *)                  die "未知参数: $1（用 --help 查看用法）" ;;
  esac
done

IP=${VOID_IP:-$IP}
[[ -n "$IP" ]] || { usage >&2; die "必须提供 --ip"; }
[[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "IP 格式不合法: $IP"
[[ -r "$INSTALLER" ]] || die "找不到 installer: $INSTALLER"

# ---------- 运行时注入本机身份 ----------
USER_NAME=${OPT_USER:-${VOID_USER:-$(id -un)}}
[[ "$USER_NAME" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]] || die "用户名不合法: $USER_NAME"
[[ "$USER_NAME" != root ]] || die "用户名不能是 root"

if [[ -z "$OPT_PUBKEY" ]]; then
  PUBFILE=${OPT_PUBKEY_FILE:-${VOID_PUBKEY_FILE:-}}
  if [[ -z "$PUBFILE" ]]; then
    for f in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_ecdsa.pub" "$HOME/.ssh/id_rsa.pub"; do
      [[ -r "$f" ]] && { PUBFILE="$f"; break; }
    done
  fi
  [[ -n "$PUBFILE" && -r "$PUBFILE" ]] || die "找不到公钥文件（用 --pubkey-file 指定）"
  PUBKEY=$(head -n1 "$PUBFILE")
  PUBKEY_SRC="$PUBFILE"
else
  PUBKEY=${VOID_PUBKEY:-$OPT_PUBKEY}
  PUBKEY_SRC="(命令行)"
fi
[[ "$PUBKEY" =~ ^(ssh-(rsa|ed25519)|ecdsa-sha2-|sk-ssh-|sk-ecdsa-) ]] || die "公钥格式不合法: $PUBKEY_SRC"

TZ_NAME=${OPT_TIMEZONE:-${VOID_TIMEZONE:-}}
if [[ -z "$TZ_NAME" ]]; then
  # /etc/localtime 通常是 /usr/share/zoneinfo/<Area>/<City> 的符号链接
  tzpath=$(readlink -f /etc/localtime 2>/dev/null || true)
  TZ_NAME=${tzpath#*/zoneinfo/}
  [[ "$TZ_NAME" != "$tzpath" && -n "$TZ_NAME" ]] || TZ_NAME=$(timedatectl show -p Timezone --value 2>/dev/null || true)
fi
[[ -n "$TZ_NAME" ]] || die "无法推断时区（用 --timezone 指定）"

LOC_NAME=${OPT_LOCALE:-${VOID_LOCALE:-}}
# 默认不覆盖 locale：installer 用中性的 en_US.UTF-8。
# 本机 LANG 常是 zh_CN.UTF-8，静默注入会改变装出来的系统语言环境。
LOCALE_ARG=()
[[ -n "$LOC_NAME" ]] && LOCALE_ARG=(--locale "$LOC_NAME")

# ---------- 展示计划 ----------
log "运行计划"
printf '  目标 live CD      : %s@%s\n' "$LIVE_USER" "$IP"
printf '  installer         : %s\n' "$INSTALLER"
printf '  注入用户名        : %s\n' "$USER_NAME"
printf '  注入公钥          : %s\n' "$PUBKEY_SRC"
printf '  公钥指纹          : %s\n' "$(printf '%s\n' "$PUBKEY" | ssh-keygen -lf - 2>/dev/null | awk '{print $2}' || echo '?')"
printf '  注入时区          : %s\n' "$TZ_NAME"
printf '  注入 locale       : %s\n' "${LOC_NAME:-<沿用 installer 默认>}"
for kv in "hostname:${OPT_HOSTNAME:-}" "repo:${OPT_REPO:-}" "disk:${OPT_DISK:-}" \
          "initial-password:${OPT_INITIAL_PASSWORD:+<已设置>}"; do
  k=${kv%%:*}; v=${kv#*:}; [[ -n "$v" ]] && printf '  覆盖 %-16s: %s\n' "$k" "$v"
done
printf '  额外参数          : %s\n' "${OPT_EXTRA[*]:-<无>}"

if (( DRY_RUN )); then
  log "--dry-run：不连接、不传输、不安装"
  exit 0
fi

# ---------- SSH_ASKPASS：只在运行时把 live CD 口令交给 ssh ----------
ASKPASS=$(mktemp "${TMPDIR:-/tmp}/void-live-askpass.XXXXXX") || die "无法创建 askpass"
chmod 700 "$ASKPASS"
cat >"$ASKPASS" <<EOF
#!/bin/sh
printf '%s\\n' '$LIVE_PASSWORD'
EOF
trap 'rm -f "$ASKPASS" "$ASKPASS.runner" "${PUBKEY_TMP:-}" 2>/dev/null || true' EXIT INT TERM

ssh_live() {
  DISPLAY=:0 SSH_ASKPASS="$ASKPASS" SSH_ASKPASS_REQUIRE=force \
    setsid ssh "${LIVE_SSH_OPTS[@]}" "$LIVE_USER@$IP" "$@"
}
scp_live() {
  DISPLAY=:0 SSH_ASKPASS="$ASKPASS" SSH_ASKPASS_REQUIRE=force \
    setsid scp "${LIVE_SSH_OPTS[@]}" "$@" "$LIVE_USER@$IP:$REMOTE_DIR/"
}

# ---------- 1) 连通性 / 环境校验 ----------
log "1) 校验 live CD"
probe=$(ssh_live 'echo LIVE_OK; id -un; [ -d /sys/firmware/efi ] && echo UEFI || echo BIOS; lsblk -dn -o SIZE /dev/vda 2>/dev/null || true' 2>&1) || die "无法登录 live CD: $probe"
printf '%s\n' "$probe" | sed 's/^/  /'
printf '%s\n' "$probe" | grep -q LIVE_OK || die "live CD 响应异常"
printf '%s\n' "$probe" | grep -q UEFI || die "目标不是 UEFI 启动（installer 只支持 UEFI）"

# ---------- 2) 传输 installer + 公钥 ----------
log "2) 传输 installer 与公钥"
PUBKEY_TMP=$(mktemp "${TMPDIR:-/tmp}/void-live-pubkey.XXXXXX")
chmod 600 "$PUBKEY_TMP"
printf '%s\n' "$PUBKEY" >"$PUBKEY_TMP"
scp_live "$INSTALLER" "$PUBKEY_TMP" || die "scp 失败"
# 远端路径：scp 保留本机文件名，公钥用固定名字便于引用
ssh_live "chmod +x '$REMOTE_DIR/$(basename "$INSTALLER")'; mv -f '$REMOTE_DIR/$(basename "$PUBKEY_TMP")' '$REMOTE_DIR/void-provision.pub'; chmod 644 '$REMOTE_DIR/void-provision.pub'" || die "远端准备失败"

# ---------- 3) 组装 installer 参数（身份全部来自运行时） ----------
args=(--user "$USER_NAME" --pubkey-file "$REMOTE_DIR/void-provision.pub"
      --timezone "$TZ_NAME")
((${#LOCALE_ARG[@]})) && args+=("${LOCALE_ARG[@]}")
[[ -n "$OPT_HOSTNAME" ]]         && args+=(--hostname "$OPT_HOSTNAME")
[[ -n "$OPT_REPO" ]]             && args+=(--repo "$OPT_REPO")
[[ -n "$OPT_DISK" ]]             && args+=(--disk "$OPT_DISK")
[[ -n "$OPT_INITIAL_PASSWORD" ]] && args+=(--initial-password "$OPT_INITIAL_PASSWORD")
((${#OPT_EXTRA[@]})) && args+=("${OPT_EXTRA[@]}")

log "3) 在 live CD 上执行安装（输出即 installer 日志）"
REMOTE_RUNNER="$REMOTE_DIR/void-provision-run.sh"
{
  printf '#!/bin/sh\n'
  printf 'exec sudo -n %q' "$REMOTE_DIR/$(basename "$INSTALLER")"
  for a in "${args[@]}"; do printf ' %q' "$a"; done
  printf '\n'
} >"$ASKPASS.runner"
chmod 700 "$ASKPASS.runner"
scp_live "$ASKPASS.runner" || die "传输执行脚本失败"
ssh_live "mv -f '$REMOTE_DIR/$(basename "$ASKPASS.runner")' '$REMOTE_RUNNER'; chmod 700 '$REMOTE_RUNNER'" || die "远端准备失败"
printf '  %s  (%s 个参数)\n' "$REMOTE_RUNNER" "${#args[@]}"
echo "--------------------------------------------------------------"
ssh_live "'$REMOTE_RUNNER'" || {
  rc=$?; die "installer 返回 rc=$rc（日志在 live CD: /var/log/void-fresh-install.log）"; }
echo "--------------------------------------------------------------"
ssh_live "rm -f '$REMOTE_RUNNER' '$REMOTE_DIR/void-provision.pub'" 2>/dev/null || true

log "完成。installer 日志：live CD /var/log/void-fresh-install.log（也复制进目标系统 /root/）"
log "虚机未重启。要进新系统：virsh console <domain> 或改 boot order 后开机。"
