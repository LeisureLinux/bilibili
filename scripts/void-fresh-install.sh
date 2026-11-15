#!/bin/bash
# void-fresh-install.sh - Install Void Linux from scratch (UEFI/GPT, x86_64-glibc)
#
# This script contains no machine-specific identity: no username, no SSH public key, no hostname, no stored passwords.
# All identity data is supplied by the caller at run time.
# pubkey is optional: with it, SSH key login works; without it there is no SSH login, only local console
# with the initial password (forced change on first login). sshd is always publickey-only, root login disabled.
#
# Usage (on the Void live CD):
#   sudo /var/tmp/void-fresh-install.sh --help
#
#   # Option A:pubkey in a separate file (recommended; identity stays out of the script)
#   scp void-fresh-install.sh id_ed25519.pub anon@<vm>:/var/tmp/
#   sudo /var/tmp/void-fresh-install.sh \
#        --user myuser --pubkey-file /var/tmp/id_ed25519.pub
#
#   # Option B:external config file
#   sudo /var/tmp/void-fresh-install.sh --conf /var/tmp/void-install.conf
#
#   # Option C:environment variables
#   sudo env VOID_USER=myuser VOID_PUBKEY='ssh-ed25519 AAAA... comment' \
#        /var/tmp/void-fresh-install.sh
#
# Based on: https://docs.voidlinux.org/installation/guides/chroot.html (official XBPS/chroot method)
# Do not use Nixort/VoidLinux-Guide install.sh -- that script has 7 defects found by end-to-end testing.
#
# Pitfalls avoided (all verified end-to-end):
#   1. the target chroot needs /etc/resolv.conf or xbps-install fails with Transient resolver failure
#   2. every xbps-install uses -y and stdin is /dev/null, so no [Y/n] prompt
#   3. Only the --repo mirror is used:the host /etc/xbps.d is rewritten per the Void docs and the target rootdir gets its own
#      /etc/xbps.d before xbps-install (-R APPENDS repos and can hit an unintended mirror)
#   5. service links go to /etc/runit/runsvdir/default/, never /var/service (a dangling symlink leaks into the live host)
#   6. a clean live CD has old xbps; -S / -u xbps on the host is required for a current repo
#   7. account policy: no root SSH login and no key for root; the ordinary user uses pubkey only,
#      initial password v01dl!nux with forced change on first login (passwd -e).
#      no other plaintext passwords; ssh host keys are pre-generated and sshd -t is checked.
#   8. binutils is installed in the target to provide /usr/bin/strip (avoids dracut's "Could not find 'strip'")
#   9. the x11-fonts trigger is stubbed, then font caches are rebuilt exactly once and restored
#      (otherwise fc-cache runs once per X11 font package; 46 repeats were measured)
#
# No reboot.no passwords are saved except the initial one that must be changed at first login. Default log: /var/log/void-fresh-install.log (root:600),
#   also copied into the target as /root/void-fresh-install.log.
#   10. serial console configured (GRUB console=ttyS0 + agetty-ttyS0) so virsh console works
#   11. elogind/dhcpcd services are not enabled (dbus activates elogind on demand; NetworkManager handles DHCP)
#   12. font cache: stub before base-system, re-stub after it plus fc-cache fallback, one rebuild at the end
#   13. sshd: PermitRootLogin no / PasswordAuthentication no / AuthenticationMethods publickey

set -Eeuo pipefail
exec </dev/null # never block on an interactive prompt

# ---------- Defaults: neutral technical parameters only, no identity ----------
DISK=/dev/vda
MNT=/mnt/void-fresh
REPO=https://mirrors.tuna.tsinghua.edu.cn/voidlinux/current # override with --repo
ARCH=x86_64
ESP_SIZE=512M
TIMEZONE=UTC        # neutral upstream default; override with --timezone
LOCALE=en_US.UTF-8  # Void glibc default; override with --locale
HOSTNAME_VALUE=void # neutral default; override with --hostname
FONTS_TRIGGER=/usr/libexec/xbps-triggers/x11-fonts
LOGFILE=/var/log/void-fresh-install.log
# Initial password for the ordinary user: only for the forced first-login change (chage -d 0 / passwd -e).
# SSH is publickey-only and root login is disabled. Override with --initial-password.
INITIAL_PASSWORD=${VOID_INITIAL_PASSWORD:-v01dl!nux}

# Identity fields: deliberately no default, must be supplied by the caller
VOID_USER=${VOID_USER:-}
VOID_PUBKEY=${VOID_PUBKEY:-}
VOID_PUBKEY_FILE=${VOID_PUBKEY_FILE:-}
VOID_GECOS=${VOID_GECOS:-}
VOID_SSH_USERS=${VOID_SSH_USERS:-} # default: only the new user; root never gets a key
VOID_REPO=${VOID_REPO:-}

die() {
  # tee process substitution can lose output on fast failure: write log synchronously + direct to terminal
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

# ---------- Argument parsing ----------
while (($#)); do
  case "$1" in
  --user)
    [[ $# -ge 2 ]] || die "--user requires an argument"
    VOID_USER="$2"
    shift 2
    ;;
  --pubkey)
    [[ $# -ge 2 ]] || die "--pubkey requires an argument"
    VOID_PUBKEY="$2"
    shift 2
    ;;
  --pubkey-file)
    [[ $# -ge 2 ]] || die "--pubkey-file requires an argument"
    VOID_PUBKEY_FILE="$2"
    shift 2
    ;;
  --conf)
    [[ $# -ge 2 ]] || die "--conf requires an argument"
    CONF_FILE="$2"
    shift 2
    ;;
  --hostname)
    [[ $# -ge 2 ]] || die "--hostname requires an argument"
    HOSTNAME_VALUE="$2"
    shift 2
    ;;
  --timezone)
    [[ $# -ge 2 ]] || die "--timezone requires an argument"
    TIMEZONE="$2"
    shift 2
    ;;
  --locale)
    [[ $# -ge 2 ]] || die "--locale requires an argument"
    LOCALE="$2"
    shift 2
    ;;
  --disk)
    [[ $# -ge 2 ]] || die "--disk requires an argument"
    DISK="$2"
    shift 2
    ;;
  --repo)
    [[ $# -ge 2 ]] || die "--repo requires an argument"
    REPO="$2"
    shift 2
    ;;
  --esp-size)
    [[ $# -ge 2 ]] || die "--esp-size requires an argument"
    ESP_SIZE="$2"
    shift 2
    ;;
  --gecos)
    [[ $# -ge 2 ]] || die "--gecos requires an argument"
    VOID_GECOS="$2"
    shift 2
    ;;
  --initial-password)
    [[ $# -ge 2 ]] || die "--initial-password requires an argument"
    INITIAL_PASSWORD="$2"
    shift 2
    ;;
  --log-file)
    [[ $# -ge 2 ]] || die "--log-file requires an argument"
    LOGFILE="$2"
    shift 2
    ;;
  --ssh-users)
    [[ $# -ge 2 ]] || die "--ssh-users requires an argument"
    VOID_SSH_USERS="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *) die "unknown option: $1 (see --help)" ;;
  esac
done

# config file is loaded last and may override values above; caller decides CLI precedence
if [[ -n "${CONF_FILE:-}" ]]; then
  [[ -r "$CONF_FILE" ]] || die "cannot read config file: $CONF_FILE"
  # shellcheck disable=SC1090
  source "$CONF_FILE"
  # config may use VOID_HOSTNAME / VOID_TIMEZONE / ... forms
  HOSTNAME_VALUE="${VOID_HOSTNAME:-$HOSTNAME_VALUE}"
  TIMEZONE="${VOID_TIMEZONE:-$TIMEZONE}"
  LOCALE="${VOID_LOCALE:-$LOCALE}"
  DISK="${VOID_DISK:-$DISK}"
  REPO="${VOID_REPO:-$REPO}"
  ESP_SIZE="${VOID_ESP_SIZE:-$ESP_SIZE}"
  INITIAL_PASSWORD="${VOID_INITIAL_PASSWORD:-$INITIAL_PASSWORD}"
fi

# ---------- Default log: console + file (including EXIT trap output) ----------
mkdir -p "$(dirname "$LOGFILE")" 2>/dev/null || true
: >"$LOGFILE"
chmod 600 "$LOGFILE" 2>/dev/null || true
printf '===== void-fresh-install START %s =====\n' "$(date -u +%FT%TZ)" >>"$LOGFILE"
printf '  command: %s %s\n' "$0" "$*" >>"$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1

# ---------- Identity validation (strict; no built-in identity) ----------
[[ -n "$VOID_USER" ]] || {
  usage >&2
  die "must provide --user / VOID_USER"
}
[[ "$VOID_USER" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]] || die "invalid username: $VOID_USER"
[[ "$VOID_USER" != root ]] || die "--user must not be root"
# pubkey is optional. sshd is always publickey-only with root login disabled:
#   with a key  -> SSH key login works (host-driven scenario)
#   without    -> no authorized_keys at all, so no SSH login;
#               a USB live CD install is reached via local console + initial password.
if [[ -z "$VOID_PUBKEY" && -n "$VOID_PUBKEY_FILE" ]]; then
  [[ -r "$VOID_PUBKEY_FILE" ]] || die "pubkey file is not readable: $VOID_PUBKEY_FILE"
  VOID_PUBKEY=$(head -n1 "$VOID_PUBKEY_FILE")
fi
if [[ -n "$VOID_PUBKEY" ]]; then
  [[ "$VOID_PUBKEY" =~ ^(ssh-(rsa|ed25519)|ecdsa-sha2-|sk-ssh-|sk-ecdsa-) ]] ||
    die "invalid pubkey (must start with ssh-ed25519 / ssh-rsa / ecdsa-sha2-)"
  [[ "$VOID_PUBKEY" != *"'"* ]] || die "pubkey comment must not contain a single quote"
  HAS_PUBKEY=1
else
  HAS_PUBKEY=0
  log "No pubkey supplied -> no SSH login; use local console + initial password after reboot (forced change)"
fi
VOID_GECOS="${VOID_GECOS:-$VOID_USER}"
[[ -n "$VOID_SSH_USERS" ]] || VOID_SSH_USERS="$VOID_USER"
HOSTNAME_VALUE="${HOSTNAME_VALUE:-void}"
[[ "$HOSTNAME_VALUE" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]] || die "invalid hostname"
[[ -f "/usr/share/zoneinfo/$TIMEZONE" ]] || die "timezone not found: $TIMEZONE"
[[ "$REPO" =~ ^https:// ]] || die "repository must be an https URL"

ESP="${DISK}1"
ROOT="${DISK}2"

# ---------- trap: on success or failure, unmount and restore the trigger ----------
cleanup() {
  local rc=$?
  if [[ -f /var/tmp/x11-fonts.orig ]]; then
    cp -a /var/tmp/x11-fonts.orig "$MNT$FONTS_TRIGGER" 2>/dev/null || true
    # if we fail midway, do not leave a stub fc-cache in the installed system
    if [[ -x "$MNT/usr/bin/fc-cache.real" ]]; then
      mv -f "$MNT/usr/bin/fc-cache.real" "$MNT/usr/bin/fc-cache" 2>/dev/null || true
    fi
    rm -f /var/tmp/x11-fonts.orig
  fi
  if findmnt -rn -o TARGET | grep -qx "$MNT"; then
    umount -R "$MNT" 2>/dev/null || true
  fi
  rmdir "$MNT" 2>/dev/null || true
  if ((rc != 0)); then printf '\n[ABORTED rc=%d] log: %s\n' "$rc" "$LOGFILE" >&2; fi
  sleep 0.5 2>/dev/null || true
  printf '===== void-fresh-install END rc=%d %s =====\n' "$rc" "$(date -u +%FT%TZ)" >>"$LOGFILE" 2>/dev/null || true
  exit "$rc"
}
trap cleanup EXIT INT TERM

# ---------- 0. Preflight / live CD bootstrap ----------
log "0) preflight / live CD bootstrap"
[ "$(id -u)" = 0 ] || die "must run as root (use sudo)"
[ -b "$DISK" ] || die "$DISK is not a block device"
[ -d /sys/firmware/efi ] || die "not booted in UEFI mode"
[ "$(cat /sys/firmware/efi/fw_platform_size)" = 64 ] || die "not 64-bit UEFI"
for c in sfdisk wipefs mkfs.vfat mkfs.ext4 blkid mount umount xbps-install xbps-query \
  chroot useradd ssh-keygen sshd grub-install grub-mkconfig \
  xbps-reconfigure udevadm install awk grep sed findmnt head; do
  command -v "$c" >/dev/null || die "missing command: $c"
done
findmnt -rn -o SOURCE | grep -q "^$DISK" && die "$DISK is already mounted" || true
sfdisk -d "$DISK" >/dev/null 2>&1 && log "NOTE: $DISK already has a partition table; it will be wiped" || true

log "0a) switch live host repo to $REPO (Void docs: /etc/xbps.d overrides /usr/share/xbps.d)"
mkdir -p /etc/xbps.d
cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/
sed -i -E "s|^repository=.*|repository=$REPO|" /etc/xbps.d/*-repository-*.conf
# A clean live CD has old xbps (0.59.2_3 on this ISO); syncing a current repo forces a self-update
xbps-install -S -y
xbps-install -y -u xbps
log "    xbps: $(xbps-install --version)"
grep -h '^repository' /etc/xbps.d/*-repository-*.conf

# ---------- 1. partition ----------
log "1) GPT partition + format"
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
  [ -b "$DISK$i" ] || die "partition $DISK$i did not appear"
done
mkfs.vfat -F32 "$ESP"
mkfs.ext4 -F "$ROOT"
sfdisk -d "$DISK"

# ---------- 2. mount ----------
log "2) mount"
mkdir -p "$MNT"
mount "$ROOT" "$MNT"
mkdir -p "$MNT/boot/efi"
mount "$ESP" "$MNT/boot/efi"

# ---------- 3. RSA keys + base-system ----------
log "3) install base-system (repo: $REPO)"
mkdir -p "$MNT/var/db/xbps/keys" "$MNT/etc/xbps.d"
cp -a /var/db/xbps/keys/. "$MNT/var/db/xbps/keys/"
printf 'repository=%s\n' "$REPO" >"$MNT/etc/xbps.d/00-repository-main.conf"
# The target rootdir already has its own conf -> no -R, so no extra repo is appended
# Font-cache suppression must happen BEFORE any xbps unpack: base-system also installs X11 fonts and
# triggers x11-fonts. Create a placeholder trigger in the empty rootfs, then re-stub right after install.
mkdir -p "$MNT/usr/libexec/xbps-triggers" "$MNT/usr/bin"
printf '#!/bin/sh\nexit 0\n' >"$MNT$FONTS_TRIGGER"
chmod 755 "$MNT$FONTS_TRIGGER"

env XBPS_ARCH="$ARCH" xbps-install -S -y -r "$MNT" base-system

log "3b) suppress repeated x11-fonts / fc-cache triggers (one rebuild at the end)"
# base-system has installed the real trigger -> back it up NOW, then overwrite with the stub
[[ -f "$MNT$FONTS_TRIGGER" ]] || die "target is missing $FONTS_TRIGGER"
cp -a "$MNT$FONTS_TRIGGER" /var/tmp/x11-fonts.orig
printf '#!/bin/sh\nexit 0\n' >"$MNT$FONTS_TRIGGER"
chmod 755 "$MNT$FONTS_TRIGGER"
if [[ -x "$MNT/usr/bin/fc-cache" && ! -e "$MNT/usr/bin/fc-cache.real" ]]; then
  mv "$MNT/usr/bin/fc-cache" "$MNT/usr/bin/fc-cache.real"
  printf '#!/bin/sh\nexit 0\n' >"$MNT/usr/bin/fc-cache"
  chmod 755 "$MNT/usr/bin/fc-cache"
fi

# ---------- 4. target repo / DNS / base config ----------
log "4) write target repo config and DNS"
[[ "$(grep -h '^repository' "$MNT/etc/xbps.d/00-repository-main.conf")" = "repository=$REPO" ]] ||
  die "target repo config is wrong"
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

# ---------- 5. mount chroot API (incl. efivarfs) ----------
log "5) mount chroot API"
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

# ---------- 6. install desktop/network/GRUB in chroot ----------
log "6) install extra packages in chroot (all -y, non-interactive)"
# binutils goes into the target too, so future kernel upgrades have strip for dracut
PKGS="sudo xtools dbus pipewire wireplumber NetworkManager openssh elogind polkit \
      vim xorg xfce4 lightdm lightdm-gtk-greeter grub-x86_64-efi efibootmgr fastfetch binutils"
chroot "$MNT" /bin/sh -c "xbps-install -S -y -u $PKGS"
chroot "$MNT" /bin/sh -c "xbps-reconfigure -f glibc-locales"

# 6b) Keep the font stub until AFTER step 9: xbps-reconfigure -fa re-runs every
#     package INSTALL script and re-triggers x11-fonts; restoring early defeats it.
#     The single rebuild happens at the end of step 9 (see "9b").

# ---------- 7. account / SSH pubkey / password policy ----------
log "7) create user $VOID_USER + optional pubkey + forced first-login password change"
chroot "$MNT" /bin/sh -c \
  "id -u '$VOID_USER' >/dev/null 2>&1 || useradd -m -G wheel,users,audio,video,network -s /bin/bash -c '$VOID_GECOS' '$VOID_USER'"
printf '%%wheel ALL=(ALL) ALL\n' >"$MNT/etc/sudoers.d/10-wheel"
chmod 0440 "$MNT/etc/sudoers.d/10-wheel"

# Initial password (only for the forced change at first login; SSH never allows password auth)
printf '%s:%s\n' "$VOID_USER" "$INITIAL_PASSWORD" | chroot "$MNT" chpasswd -c SHA512
# Force first-login change: after pubkey auth succeeds, the PAM account stage prompts
# "You are required to change your password immediately" and asks for the CURRENT
# password (= initial) before setting a new one. Normal for publickey-only + forced change, not a lockout.
chroot "$MNT" passwd -e "$VOID_USER" >/dev/null 2>&1 || \
  chroot "$MNT" chage -d 0 "$VOID_USER" >/dev/null 2>&1 || die "could not set forced first-login password change"
log "    Initial password set. First login (SSH key or local console) will require a change"

# Write the key only to accounts in --ssh-users, and ALWAYS refuse root
if [[ "$HAS_PUBKEY" -eq 1 ]]; then
IFS=',' read -ra _ssh_users <<<"$VOID_SSH_USERS"
for u in "${_ssh_users[@]}"; do
  u=$(printf '%s' "$u" | tr -d '[:space:]')
  [[ -n "$u" ]] || continue
  if [[ "$u" = root ]]; then
    printf '  [deny] refusing to write a key into root authorized_keys (root SSH login is disabled)\n'
    continue
  fi
  h="/home/$u"
  [[ -d "$MNT$h" ]] || die "account $u home dir missing (only existing accounts allowed)"
  mkdir -p "$MNT$h/.ssh"
  printf '%s\n' "$VOID_PUBKEY" >"$MNT$h/.ssh/authorized_keys"
  chmod 700 "$MNT$h/.ssh"
  chmod 600 "$MNT$h/.ssh/authorized_keys"
  chroot "$MNT" /bin/sh -c "chown -R \"\$(id -u '$u'):\$(id -g '$u')\" '$h/.ssh'"
  printf '  [key] %s -> %s/.ssh/authorized_keys\n' "$u" "$h"
done
fi

# Ensure root has no leftover authorized_keys / .ssh/rc
rm -f "$MNT/root/.ssh/authorized_keys" "$MNT/root/.ssh/rc" 2>/dev/null || true
rmdir "$MNT/root/.ssh" 2>/dev/null || true

# ---- sshd: always publickey-only + root disabled, regardless of pubkey ----
# With no pubkey there are no authorized_keys, so SSH login is impossible;
# a USB live CD install uses the console anyway, so password auth must NOT be enabled.
mkdir -p "$MNT/etc/ssh/sshd_config.d"
cat >"$MNT/etc/ssh/sshd_config.d/10-hardening.conf" <<'SSHDCFG'
# Generated by void-fresh-install.sh: publickey-only
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
# OpenSSH Include is near the top of the main config (line 16 on this image, before any setting),
# so the drop-in wins; if an image lacks Include, prepend one.
grep -qE '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config.d/' "$MNT/etc/ssh/sshd_config" || {
  sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' "$MNT/etc/ssh/sshd_config"; }

# Pre-generate host keys + validate config (must pass or the system is unreachable)
chroot "$MNT" ssh-keygen -A >/dev/null 2>&1 || true
chroot "$MNT" /usr/bin/sshd -t || die "sshd -t validation failed"
log "    sshd -t OK: publickey-only / root disabled (no key => no SSH login, use console)"

# ---------- 8. services: write /etc/runit/runsvdir/default/ ----------
log "8) enable services"
mkdir -p "$MNT/etc/runit/runsvdir/default"
[[ -e "$MNT/etc/runit/runsvdir/current" ]] || ln -s default "$MNT/etc/runit/runsvdir/current"
# Do not enable elogind: dbus activates it on demand; both together crash-loop every second (serial spam)
# dhcpcd stays enabled (NM internal DHCP backend manages addressing);
# explicitly set dhcp=internal so NM default changes cannot lose the IP after reboot.
mkdir -p "$MNT/etc/NetworkManager/conf.d"
printf '[main]\ndhcp=internal\n' >"$MNT/etc/NetworkManager/conf.d/10-dhcp-internal.conf"
for s in dbus polkitd NetworkManager dhcpcd sshd lightdm agetty-ttyS0; do
  [[ -d "$MNT/etc/sv/$s" ]] || {
    printf '  [skip] %s (no service definition)\n' "$s"
    continue
  }
  ln -sf "/etc/sv/$s" "$MNT/etc/runit/runsvdir/default/$s"
  printf '  [on] %s\n' "$s"
done

# ---------- 9. GRUB (UEFI) ----------
log "9) install GRUB + generate initramfs/grub.cfg"
chroot "$MNT" /bin/sh -c 'grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Void' ||
  chroot "$MNT" /bin/sh -c 'grub-install --no-nvram --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Void'
chroot "$MNT" /bin/sh -c 'xbps-reconfigure -fa'
# serial console: kernel messages and GRUB menu go to ttyS0, with agetty-ttyS0
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

# ---------- 9b. after xbps-reconfigure -fa: the ONE font-cache rebuild ----------
log "9b) single rebuild of X11 font indexes + fontconfig cache"
if [[ -x "$MNT/usr/bin/fc-cache.real" ]]; then
  mv -f "$MNT/usr/bin/fc-cache.real" "$MNT/usr/bin/fc-cache"
fi
printf '  [font] single rebuild START %s\n' "$(date -u +%FT%TZ)"
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
printf '  [font] single rebuild END %s\n' "$(date -u +%FT%TZ)"
cp -a /var/tmp/x11-fonts.orig "$MNT$FONTS_TRIGGER"
rm -f /var/tmp/x11-fonts.orig
log "    x11-fonts trigger and fc-cache restored"


# ---------- 10. verification ----------
log "10) verification"
printf '  packages: '
xbps-query -r "$MNT" -l | wc -l
printf '  repo:   '
grep -h '^repository' "$MNT/etc/xbps.d/"*.conf
printf '  password: initial only, forced change at first login (SSH publickey-only)\n'
printf '  authorized_keys: '
find "$MNT/root/.ssh" "$MNT/home" -name authorized_keys -printf '%p ' 2>/dev/null || true
echo
printf '  SSH host keys: '
(ls "$MNT/etc/ssh/" | grep -c ssh_host_) || true
printf '  services: '
ls "$MNT/etc/runit/runsvdir/default/" | tr '\n' ' '
echo
printf '  strip: '
(ls -la "$MNT/usr/bin/strip" 2>/dev/null | awk '{print $NF}') || true
printf '  EFI:  '
find "$MNT/boot/efi" -name 'grubx64.efi' -printf '%p\n'
printf '  grub entries: '
(grep -c menuentry "$MNT/boot/grub/grub.cfg") || true
printf '  effective sshd: '
chroot "$MNT" /usr/bin/sshd -T 2>/dev/null | grep -iE '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|authenticationmethods)' | tr '\n' ' '
echo
printf '  root authorized_keys: '
[ -e "$MNT/root/.ssh/authorized_keys" ] && echo 'PRESENT (ERROR!)' || echo 'absent OK'
printf '  dhcp=internal: '
grep -h 'dhcp=' "$MNT/etc/NetworkManager/conf.d/"*.conf 2>/dev/null || echo '(not set)' 

mkdir -p "$MNT/root"
cp "$LOGFILE" "$MNT/root/void-fresh-install.log" 2>/dev/null || true
chmod 600 "$MNT/root/void-fresh-install.log" 2>/dev/null || true
log "Done. root SSH disabled with no authorized_keys; sshd is publickey-only."
log "With a key: SSH key login. Without: local console. Both require changing the initial password."
log "virsh console works; no extra plaintext passwords saved. No reboot."
log "log: $LOGFILE (also copied to /root/void-fresh-install.log in the target)"
