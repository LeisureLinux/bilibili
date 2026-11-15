#!/bin/sh
# void-bootstrap.sh - fetch the installer on a Void live CD via curl|sh
#
# The Void live CD has no curl/wget, only python3. Two options:
#
# (recommended, zero extra deps) use python3, install nothing:
#   python3 -c 'import urllib.request as u,subprocess as s;p="/tmp/void-bootstrap.sh";open(p,"wb").write(u.urlopen("https://raw.githubusercontent.com/LeisureLinux/bilibili/master/scripts/void-bootstrap.sh",timeout=60).read());s.run(["sudo","-n","sh",p,"--user","alice"])'
#
# (want real curl|bash) install curl first. The ISO index is an old snapshot,
# curl-8.11.1_2.sig2 is 404 on the default mirror, so switch repo + -S; new libcurl also needs
# a libssh2 upgrade. Shortest reliable way (~2s):
#   sudo mkdir -p /etc/xbps.d
#   sudo cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/
#   sudo sed -i 's|https://repo-default.voidlinux.org|https://mirrors.tuna.tsinghua.edu.cn/voidlinux|g' /etc/xbps.d/*-repository-*.conf
#   sudo xbps-install -Syu curl libssh2
# Then:
#   curl -fsSL .../void-bootstrap.sh | sudo sh -s -- --user alice
#
# Safety:
#   * NEVER wipes the disk by itself. Without --user it only downloads and prints usage.
#   * Scenario B (local USB live CD): curl|sh + --user alice, no pubkey needed.
#     sshd is still publickey-only, so no SSH login; after reboot use console + initial password
#     with a forced change on first login.
#   * Scenario A (host-driven VM): use void-live-provision.sh --ip <IP>,
#     which injects a pubkey at run time for key-only SSH login.
#   * The installer itself has no baked-in identity; the caller supplies it at run time.
#   * No passwords or keys are written into the repo; no machine identity is assumed.
#
# Requires: python3 or curl, root (sudo -n or root shell), UEFI live CD.

set -eu

RAW_BASE="https://raw.githubusercontent.com/LeisureLinux/bilibili/master/scripts"
INSTALLER_URL="$RAW_BASE/void-fresh-install.sh"
DEST=${VOID_INSTALLER_DEST:-${TMPDIR:-/tmp}/void-fresh-install.sh}
ANSWER=""

log() { printf '\n>>> %s\n' "$*"; }
die() { printf '\n[FATAL] %s\n' "$*" >&2; exit 1; }

# ---------- args (forwarded to the installer) ----------
ARGS=""
HAS_IDENTITY=0
EXPLICIT_CONFIRM=0
while [ $# -gt 0 ]; do
  case "$1" in
    --user) HAS_IDENTITY=1 ;;   # --user alone triggers install (no SSH, console only)
    --help|-h) EXPLICIT_CONFIRM=-1 ;;   # help wins: never enter the install branch
    --yes-i-know-this-wipes-the-disk) EXPLICIT_CONFIRM=1; shift; continue ;;
  esac
  # printf %q is unavailable in sh; wrap each arg in single quotes instead
  esc=$(printf '%s' "$1" | sed "s/'/'\\\\''/g")
  ARGS="$ARGS '$esc'"
  shift
done
[ "$HAS_IDENTITY" -ge 1 ] && [ "$EXPLICIT_CONFIRM" -ge 0 ] && EXPLICIT_CONFIRM=1
[ "$EXPLICIT_CONFIRM" -lt 0 ] && EXPLICIT_CONFIRM=0

# ---------- preflight ----------
# Void live CD has only python3 (no curl/wget); prefer curl when present.
if command -v curl >/dev/null 2>&1; then
  dl() { curl -fsSL --max-time 60 "$1" -o "$2"; }
elif command -v python3 >/dev/null 2>&1; then
  dl() { python3 -c 'import sys,urllib.request,ssl; u,o=sys.argv[1],sys.argv[2]; ctx=ssl.create_default_context(); open(o,"wb").write(urllib.request.urlopen(u,timeout=60,context=ctx).read())' "$1" "$2"; }
else
  die "live CD has neither curl nor python3; cannot download"
fi
[ "$(id -u)" -eq 0 ] || die "run as root (python3 ... | sudo sh -s -- ...)"
[ -d /sys/firmware/efi ] || die "not booted in UEFI mode"

log "downloading installer -> $DEST"
dl "$INSTALLER_URL" "$DEST" || die "download failed: $INSTALLER_URL"
chmod 755 "$DEST"
printf '  bytes: %s\n' "$(wc -c <"$DEST")"
bash -n "$DEST" 2>/dev/null || die "downloaded file is not a valid bash script (or is truncated)"

# ---------- default: show usage only, no install ----------
if [ "$EXPLICIT_CONFIRM" -eq 0 ]; then
  log "installer ready (no install ran; disk untouched)"
  "$DEST" --help 2>/dev/null | head -40 || true
  cat <<'EOF'

Local USB live CD (simplest; console after reboot):
  curl -fsSL .../void-bootstrap.sh | sudo sh -s -- --user alice
  # or run the downloaded file directly: <dir>/void-fresh-install.sh --user alice
  # no pubkey => no SSH login; console uses the initial password with forced change

Inject a pubkey from another machine (key-only SSH afterwards):
  curl -fsSL .../void-bootstrap.sh | sudo sh -s -- --user alice --pubkey-file /path/alice.pub
EOF
  exit 0
fi

log "running install (target disk /dev/vda will be wiped)"
eval "'$DEST' $ARGS"
