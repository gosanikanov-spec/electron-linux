#!/usr/bin/env bash
# Electron Linux — ARM64 (aarch64) disk image for UTM on Apple Silicon Macs.
# Based on Arch Linux ARM. Produces a UEFI-bootable qcow2 image.
# Usage (on an aarch64 Linux host, as root):  ./build-arm.sh [minimal|desktop]
# Host tools: arch-chroot bsdtar sgdisk mkfs.vfat mkfs.ext4 qemu-img curl
set -euo pipefail

VARIANT="${1:-desktop}"
case "$VARIANT" in minimal|desktop) ;; *) echo "Variant must be 'minimal' or 'desktop'"; exit 1 ;; esac
[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
[[ "$(uname -m)" == aarch64 ]] || { echo "Must run on an aarch64 host (e.g. GitHub 'ubuntu-24.04-arm')"; exit 1; }
for t in arch-chroot bsdtar sgdisk mkfs.vfat mkfs.ext4 qemu-img curl losetup blkid; do
  command -v "$t" >/dev/null || { echo "Missing host tool: $t"; exit 1; }
done

SRC="$(cd "$(dirname "$0")" && pwd)"
OUT="$SRC/out"
WORK="${WORK_DIR:-/tmp/electron-arm-$VARIANT}"
IMG="$WORK/disk.raw"
MNT="$WORK/mnt"
TARBALL="ArchLinuxARM-aarch64-latest.tar.gz"
TARBALL_URL="http://os.archlinuxarm.org/os/$TARBALL"
DISK_SIZE="16G"   # sparse: the qcow2 only stores used space
LOOP=""

cleanup() {
  set +e
  if mountpoint -q "$MNT"; then umount -R "$MNT" || umount -lR "$MNT"; fi
  [[ -n "$LOOP" ]] && losetup -d "$LOOP"
}
trap cleanup EXIT

rm -rf "$WORK"; mkdir -p "$WORK" "$MNT" "$OUT"

# --- Download and verify the Arch Linux ARM root filesystem -----------------
echo ">> Downloading Arch Linux ARM rootfs"
curl -fL --retry 3 -o "$WORK/$TARBALL" "$TARBALL_URL"
curl -fL --retry 3 -o "$WORK/$TARBALL.md5" "$TARBALL_URL.md5"
(cd "$WORK" && md5sum -c "$TARBALL.md5")

# --- Partition: 512M EFI system partition + ext4 root -----------------------
echo ">> Creating disk image"
truncate -s "$DISK_SIZE" "$IMG"
sgdisk -Z -n1:0:+512M -t1:ef00 -c1:EFI -n2:0:0 -t2:8305 -c2:root "$IMG"
LOOP="$(losetup -fP --show "$IMG")"
sleep 1
mkfs.vfat -F32 -n EFI "${LOOP}p1"
mkfs.ext4 -q -L electron-root "${LOOP}p2"

mount "${LOOP}p2" "$MNT"
bsdtar -xpf "$WORK/$TARBALL" -C "$MNT"
rm -rf "$MNT"/boot/*              # kernel is reinstalled onto the ESP below
mount "${LOOP}p1" "$MNT/boot"

ROOT_UUID="$(blkid -s UUID -o value "${LOOP}p2")"
ROOT_PARTUUID="$(blkid -s PARTUUID -o value "${LOOP}p2")"
ESP_UUID="$(blkid -s UUID -o value "${LOOP}p1")"

# --- Config before packages install -----------------------------------------
# Lean installs (same as the x86 ISO)
sed -i \
  -e '/^\[options\]/a NoExtract = usr/share/doc/* usr/share/gtk-doc/* usr/share/help/* usr/share/info/*' \
  -e '/^\[options\]/a NoExtract = usr/share/locale/* !usr/share/locale/en* !usr/share/locale/locale.alias' \
  "$MNT/etc/pacman.conf"
# Generic initramfs: don't trim drivers to the build machine's hardware
sed -i '/^HOOKS=/ s/ autodetect//' "$MNT/etc/mkinitcpio.conf"

cat > "$MNT/etc/fstab" <<EOF
UUID=$ROOT_UUID  /      ext4  rw,relatime        0 1
UUID=$ESP_UUID   /boot  vfat  rw,umask=0077      0 2
EOF

# --- Shared Electron Linux files (minus x86 live-ISO-only bits) -------------
OVL="$WORK/overlay"; mkdir -p "$OVL"
cp -r "$SRC/profile/airootfs/common/." "$OVL/"
[[ -d "$SRC/profile/airootfs/$VARIANT" ]] && cp -r "$SRC/profile/airootfs/$VARIANT/." "$OVL/"
rm -f "$OVL"/etc/{passwd,shadow,group,gshadow}       # users are created with useradd instead
[[ "$VARIANT" == desktop ]] && rm -rf "$OVL/etc/systemd/system/getty@tty1.service.d"
cp -r "$OVL/." "$MNT/"
cat > "$MNT/etc/motd" <<'EOF'

  Welcome to Electron Linux (ARM64) — a clean, minimal Arch-based system.
    Wi-Fi/network:     nmtui
    Install software:  sudo pacman -S <package>

EOF

# --- Package list: shared lists minus x86-only / live-ISO-only packages -----
EXCLUDE='^(linux|linux-firmware|intel-ucode|amd-ucode|mkinitcpio-archiso|archinstall)$'
cat "$SRC/profile/packages/base.txt" "$SRC/profile/packages/$VARIANT.txt" \
  | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//' | { grep -v '^$' || true; } \
  | { grep -Ev "$EXCLUDE" || true; } | sort -u > "$MNT/root/pkgs.txt"

# --- Configure inside the image --------------------------------------------
cat > "$MNT/root/setup.sh" <<'SETUP'
#!/bin/bash
set -euo pipefail
VARIANT="$1"; ROOT_PARTUUID="$2"

pacman-key --init
pacman-key --populate archlinuxarm
pacman -Syu --noconfirm
pacman -S --noconfirm linux-aarch64                    # puts Image + initramfs on the ESP
pacman -S --noconfirm --needed $(cat /root/pkgs.txt)

[[ -f /boot/Image ]] || { echo "Kernel Image not found in /boot:"; ls -la /boot; exit 1; }

# Locale and branding
sed -i 's/^#\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
sh /etc/electron-linux/branding.sh

# Users: replace ALARM's default 'alarm' user with 'live' (no password, passwordless sudo)
userdel -r alarm 2>/dev/null || true
useradd -M -d /home/live -G wheel -s /bin/bash live
passwd -d live
passwd -l root
mkdir -p /home/live
chown -R live:live /home/live
chmod 750 /home/live
chmod 440 /etc/sudoers.d/00-live
chmod 755 /etc/electron-linux/branding.sh

# Services: NetworkManager instead of ALARM's networkd; no SSH server by default
systemctl disable systemd-networkd.service systemd-networkd.socket sshd.service 2>/dev/null || true
systemctl enable NetworkManager.service
if [[ "$VARIANT" == desktop ]]; then
  systemctl enable greetd.service
  systemctl set-default graphical.target
fi

# Bootloader: systemd-boot (also installs the fallback EFI/BOOT/BOOTAA64.EFI UTM boots from)
bootctl --no-variables --esp-path=/boot install
mkdir -p /boot/loader/entries
cat > /boot/loader/loader.conf <<EOF
default electron.conf
timeout 2
EOF
cat > /boot/loader/entries/electron.conf <<EOF
title   Electron Linux
linux   /Image
initrd  /initramfs-linux.img
options root=PARTUUID=$ROOT_PARTUUID rw quiet
EOF

# Clean up
pacman -Scc --noconfirm
rm -rf /var/cache/pacman/pkg/* /root/pkgs.txt /root/setup.sh
gpgconf --homedir /etc/pacman.d/gnupg --kill all 2>/dev/null || true
SETUP

echo ">> Configuring system inside the image"
arch-chroot "$MNT" /bin/bash /root/setup.sh "$VARIANT" "$ROOT_PARTUUID"

# --- Finish -----------------------------------------------------------------
cleanup; LOOP=""; trap - EXIT
NAME="electron-linux-$VARIANT-aarch64.qcow2"
echo ">> Compressing to $NAME"
qemu-img convert -c -O qcow2 "$IMG" "$OUT/$NAME"
(cd "$OUT" && sha256sum "$NAME" > "$NAME.sha256")
echo "Done: $OUT/$NAME"
