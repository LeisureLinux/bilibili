#!/bin/bash
# void-live-provision.sh - drive a Void live CD install from the local PC
#
# Runs on the local PC. It reads local identity (user / pubkey / timezone) AT RUN TIME,
# then logs into the live CD as anon/voidlinux and runs void-fresh-install.sh there.
# void-fresh-install.sh stays identity-free; nothing here hardcodes identity either.
#
#   ./void-live-provision.sh --ip <VM-IP>
#   ./void-live-provision.sh --ip <VM-IP> --user bob --pubkey ~/.ssh/bob.pub
#   ./void-live-provision.sh --ip <VM-IP> --timezone UTC --hostname lab
#   ./void-live-provision.sh --ip <VM-IP> --dry-run
#
# The live CD password is passed to ssh only at run time via SSH_ASKPASS, never stored.
# Does not reboot the VM; the installer prints its log path when done.

set -Eeuo pipefail

# ---------- defaults: neutral technical values ----------
IP=""
LIVE_USER=anon
LIVE_PASSWORD=voidlinux          # documented default password of the Void live CD
LIVE_SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
               -o ConnectTimeout=10 -o PreferredAuthentications=password
               -o PubkeyAuthentication=no -o NumberOfPasswordPrompts=1)
# installer defaults to the directory of this script (all scripts live together); no absolute local path
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
INSTALLER=${INSTALLER:-$SCRIPT_DIR/void-fresh-install.sh}
REMOTE_DIR=${REMOTE_DIR:-/var/tmp}
DRY_RUN=0
KEEP_ASKPASS=0

# identity fields: derived at run time, or overridden by args
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
  --ip ADDRESS             IP of the live CD VM (the only required arg)

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

# ---------- arguments ----------
while (($#)); do
  case "$1" in
    --ip)               [[ $# -ge 2 ]] || die "--ip requires an argument"; IP="$2"; shift 2 ;;
    --ip=*)             IP="${1#--ip=}"; shift ;;
    --user)             [[ $# -ge 2 ]] || die "--user requires an argument"; OPT_USER="$2"; shift 2 ;;
    --pubkey-file)      [[ $# -ge 2 ]] || die "--pubkey-file requires an argument"; OPT_PUBKEY_FILE="$2"; shift 2 ;;
    --pubkey)           [[ $# -ge 2 ]] || die "--pubkey requires an argument"; OPT_PUBKEY="$2"; shift 2 ;;
    --timezone)         [[ $# -ge 2 ]] || die "--timezone requires an argument"; OPT_TIMEZONE="$2"; shift 2 ;;
    --locale)           [[ $# -ge 2 ]] || die "--locale requires an argument"; OPT_LOCALE="$2"; shift 2 ;;
    --hostname)         [[ $# -ge 2 ]] || die "--hostname requires an argument"; OPT_HOSTNAME="$2"; shift 2 ;;
    --repo)             [[ $# -ge 2 ]] || die "--repo requires an argument"; OPT_REPO="$2"; shift 2 ;;
    --disk)             [[ $# -ge 2 ]] || die "--disk requires an argument"; OPT_DISK="$2"; shift 2 ;;
    --initial-password) [[ $# -ge 2 ]] || die "--initial-password requires an argument"; OPT_INITIAL_PASSWORD="$2"; shift 2 ;;
    --installer)        [[ $# -ge 2 ]] || die "--installer requires an argument"; INSTALLER="$2"; shift 2 ;;
    --live-user)        [[ $# -ge 2 ]] || die "--live-user requires an argument"; LIVE_USER="$2"; shift 2 ;;
    --live-password)    [[ $# -ge 2 ]] || die "--live-password requires an argument"; LIVE_PASSWORD="$2"; shift 2 ;;
    --extra)            [[ $# -ge 2 ]] || die "--extra requires an argument"; OPT_EXTRA+=("$2"); shift 2 ;;
    --dry-run)          DRY_RUN=1; shift ;;
    -h|--help)          usage; exit 0 ;;
    *)                  die "unknown option: $1 (see --help)" ;;
  esac
done

IP=${VOID_IP:-$IP}
[[ -n "$IP" ]] || { usage >&2; die "--ip is required"; }
[[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "invalid IP: $IP"
[[ -r "$INSTALLER" ]] || die "installer not found: $INSTALLER"

# ---------- inject local identity at run time ----------
USER_NAME=${OPT_USER:-${VOID_USER:-$(id -un)}}
[[ "$USER_NAME" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]] || die "invalid username: $USER_NAME"
[[ "$USER_NAME" != root ]] || die "username must not be root"

if [[ -z "$OPT_PUBKEY" ]]; then
  PUBFILE=${OPT_PUBKEY_FILE:-${VOID_PUBKEY_FILE:-}}
  if [[ -z "$PUBFILE" ]]; then
    for f in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_ecdsa.pub" "$HOME/.ssh/id_rsa.pub"; do
      [[ -r "$f" ]] && { PUBFILE="$f"; break; }
    done
  fi
  [[ -n "$PUBFILE" && -r "$PUBFILE" ]] || die "no pubkey file found (use --pubkey-file)"
  PUBKEY=$(head -n1 "$PUBFILE")
  PUBKEY_SRC="$PUBFILE"
else
  PUBKEY=${VOID_PUBKEY:-$OPT_PUBKEY}
  PUBKEY_SRC="(command line)"
fi
[[ "$PUBKEY" =~ ^(ssh-(rsa|ed25519)|ecdsa-sha2-|sk-ssh-|sk-ecdsa-) ]] || die "invalid pubkey: $PUBKEY_SRC"

TZ_NAME=${OPT_TIMEZONE:-${VOID_TIMEZONE:-}}
if [[ -z "$TZ_NAME" ]]; then
  # /etc/localtime is usually a symlink to /usr/share/zoneinfo/<Area>/<City>
  tzpath=$(readlink -f /etc/localtime 2>/dev/null || true)
  TZ_NAME=${tzpath#*/zoneinfo/}
  [[ "$TZ_NAME" != "$tzpath" && -n "$TZ_NAME" ]] || TZ_NAME=$(timedatectl show -p Timezone --value 2>/dev/null || true)
fi
[[ -n "$TZ_NAME" ]] || die "cannot detect timezone (use --timezone)"

LOC_NAME=${OPT_LOCALE:-${VOID_LOCALE:-}}
# Do not override locale by default: the installer uses neutral en_US.UTF-8.
# The local LANG is often zh_CN.UTF-8; injecting it silently would change the target locale.
LOCALE_ARG=()
[[ -n "$LOC_NAME" ]] && LOCALE_ARG=(--locale "$LOC_NAME")

# ---------- show plan ----------
log "run plan"
printf '  target live CD    : %s@%s\n' "$LIVE_USER" "$IP"
printf '  installer         : %s\n' "$INSTALLER"
printf '  user              : %s\n' "$USER_NAME"
printf '  pubkey            : %s\n' "$PUBKEY_SRC"
printf '  pubkey fingerprint: %s\n' "$(printf '%s\n' "$PUBKEY" | ssh-keygen -lf - 2>/dev/null | awk '{print $2}' || echo '?')"
printf '  timezone          : %s\n' "$TZ_NAME"
printf '  locale            : %s\n' "${LOC_NAME:-<installer default>}"
for kv in "hostname:${OPT_HOSTNAME:-}" "repo:${OPT_REPO:-}" "disk:${OPT_DISK:-}" \
          "initial-password:${OPT_INITIAL_PASSWORD:+<set>}"; do
  k=${kv%%:*}; v=${kv#*:}; [[ -n "$v" ]] && printf '  override %-15s: %s\n' "$k" "$v"
done
printf '  extra args        : %s\n' "${OPT_EXTRA[*]:-<none>}"

if (( DRY_RUN )); then
  log "--dry-run: no connect, no transfer, no install"
  exit 0
fi

# ---------- SSH_ASKPASS: hand the live CD password to ssh only at run time ----------
ASKPASS=$(mktemp "${TMPDIR:-/tmp}/void-live-askpass.XXXXXX") || die "cannot create askpass"
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

# ---------- 1) connectivity / environment check ----------
log "1) verify live CD"
probe=$(ssh_live 'echo LIVE_OK; id -un; [ -d /sys/firmware/efi ] && echo UEFI || echo BIOS; lsblk -dn -o SIZE /dev/vda 2>/dev/null || true' 2>&1) || die "cannot log into live CD: $probe"
printf '%s\n' "$probe" | sed 's/^/  /'
printf '%s\n' "$probe" | grep -q LIVE_OK || die "unexpected live CD response"
printf '%s\n' "$probe" | grep -q UEFI || die "target is not UEFI (installer supports UEFI only)"

# ---------- 2) transfer installer + pubkey ----------
log "2) transfer installer and pubkey"
PUBKEY_TMP=$(mktemp "${TMPDIR:-/tmp}/void-live-pubkey.XXXXXX")
chmod 600 "$PUBKEY_TMP"
printf '%s\n' "$PUBKEY" >"$PUBKEY_TMP"
scp_live "$INSTALLER" "$PUBKEY_TMP" || die "scp failed"
# remote paths: scp keeps local names; the pubkey gets a fixed name for easy reference
ssh_live "chmod +x '$REMOTE_DIR/$(basename "$INSTALLER")'; mv -f '$REMOTE_DIR/$(basename "$PUBKEY_TMP")' '$REMOTE_DIR/void-provision.pub'; chmod 644 '$REMOTE_DIR/void-provision.pub'" || die "remote prep failed"

# ---------- 3) build installer args (identity all from run time) ----------
args=(--user "$USER_NAME" --pubkey-file "$REMOTE_DIR/void-provision.pub"
      --timezone "$TZ_NAME")
((${#LOCALE_ARG[@]})) && args+=("${LOCALE_ARG[@]}")
[[ -n "$OPT_HOSTNAME" ]]         && args+=(--hostname "$OPT_HOSTNAME")
[[ -n "$OPT_REPO" ]]             && args+=(--repo "$OPT_REPO")
[[ -n "$OPT_DISK" ]]             && args+=(--disk "$OPT_DISK")
[[ -n "$OPT_INITIAL_PASSWORD" ]] && args+=(--initial-password "$OPT_INITIAL_PASSWORD")
((${#OPT_EXTRA[@]})) && args+=("${OPT_EXTRA[@]}")

log "3) run install on live CD (output is the installer log)"
REMOTE_RUNNER="$REMOTE_DIR/void-provision-run.sh"
{
  printf '#!/bin/sh\n'
  printf 'exec sudo -n %q' "$REMOTE_DIR/$(basename "$INSTALLER")"
  for a in "${args[@]}"; do printf ' %q' "$a"; done
  printf '\n'
} >"$ASKPASS.runner"
chmod 700 "$ASKPASS.runner"
scp_live "$ASKPASS.runner" || die "failed to transfer runner script"
ssh_live "mv -f '$REMOTE_DIR/$(basename "$ASKPASS.runner")' '$REMOTE_RUNNER'; chmod 700 '$REMOTE_RUNNER'" || die "remote prep failed"
printf '  %s  (%s args)\n' "$REMOTE_RUNNER" "${#args[@]}"
echo "--------------------------------------------------------------"
ssh_live "'$REMOTE_RUNNER'" || {
  rc=$?; die "installer returned rc=$rc (log on live CD: /var/log/void-fresh-install.log)"; }
echo "--------------------------------------------------------------"
ssh_live "rm -f '$REMOTE_RUNNER' '$REMOTE_DIR/void-provision.pub'" 2>/dev/null || true

log "Done. installer log: live CD /var/log/void-fresh-install.log (also copied to /root/ in the target)"
log "VM not rebooted. To enter the new system: virsh console <domain>, or change boot order and start."
