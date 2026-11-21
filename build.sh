#!/usr/bin/env bash
# Electron Linux — Arch-based ISO builder (archiso).
# Usage (on Arch, as root):  ./build.sh [minimal|desktop]
set -euo pipefail

VARIANT="${1:-minimal}"
case "$VARIANT" in minimal|desktop) ;; *) echo "Variant must be 'minimal' or 'desktop'"; exit 1 ;; esac
[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
command -v mkarchiso >/dev/null || { echo "Install archiso first: pacman -S archiso"; exit 1; }

SRC="$(cd "$(dirname "$0")" && pwd)"
BASE=/usr/share/archiso/configs/baseline     # upstream minimal profile: known-good boot config
BUILD="${BUILD_DIR:-/tmp/electron-linux-$VARIANT}"
PROFILE="$BUILD/profile"
OUT="$SRC/out"

rm -rf "$BUILD"; mkdir -p "$PROFILE" "$OUT"
cp -a "$BASE/." "$PROFILE/"

# --- Packages: upstream baseline (bootloader, initramfs hooks) + ours ---------
cat "$BASE/packages.x86_64" "$SRC/profile/packages/base.txt" "$SRC/profile/packages/$VARIANT.txt" \
  | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//' | { grep -v '^$' || true; } | sort -u \
  > "$PROFILE/packages.x86_64"

# --- Filesystem overlay ------------------------------------------------------
cp -a "$SRC/profile/airootfs/common/." "$PROFILE/airootfs/"
[[ -d "$SRC/profile/airootfs/$VARIANT" ]] && cp -a "$SRC/profile/airootfs/$VARIANT/." "$PROFILE/airootfs/"

# --- Services (symlinks are created here so the repo stays Windows-friendly) -
SYS="$PROFILE/airootfs/etc/systemd/system"
mkdir -p "$SYS/multi-user.target.wants"
rm -f "$SYS"/multi-user.target.wants/{systemd-networkd,iwd}.service \
      "$SYS"/sockets.target.wants/systemd-networkd.socket \
      "$SYS"/network-online.target.wants/systemd-networkd-wait-online.service
ln -sf /usr/lib/systemd/system/NetworkManager.service "$SYS/multi-user.target.wants/NetworkManager.service"
if [[ "$VARIANT" == desktop ]]; then
  # greetd owns tty1 and autologins into Hyprland, so drop the console autologin
  rm -rf "$SYS/getty@tty1.service.d"
  ln -sf /usr/lib/systemd/system/greetd.service "$SYS/display-manager.service"
  ln -sf /usr/lib/systemd/system/graphical.target "$SYS/default.target"
fi

# --- Boot menu branding ------------------------------------------------------
{ grep -rl 'Arch Linux' "$PROFILE"/efiboot "$PROFILE"/syslinux "$PROFILE"/grub 2>/dev/null || true; } \
  | xargs -r sed -i 's/Arch Linux/Electron Linux/g'

# --- Profile metadata (appended; later assignments override baseline's) -------
cat >> "$PROFILE/profiledef.sh" <<EOF

# ---- Electron Linux overrides ----
iso_name="electron-linux-$VARIANT"
iso_label="ELECTRON_\$(date --date="@\${SOURCE_DATE_EPOCH:-\$(date +%s)}" +%Y%m)"
iso_publisher="Electron Linux"
iso_application="Electron Linux ($VARIANT)"
file_permissions+=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/etc/sudoers.d/00-live"]="0:0:440"
  ["/etc/electron-linux/branding.sh"]="0:0:755"
  ["/home/live"]="1000:1000:750"
)
EOF

# --- Keep the image lean: skip docs and non-English translations --------------
sed -i \
  -e '/^\[options\]/a NoExtract = usr/share/doc/* usr/share/gtk-doc/* usr/share/help/* usr/share/info/*' \
  -e '/^\[options\]/a NoExtract = usr/share/locale/* !usr/share/locale/en* !usr/share/locale/locale.alias' \
  "$PROFILE/pacman.conf"

# --- Build -------------------------------------------------------------------
mkarchiso -v -w "$BUILD/work" -o "$OUT" "$PROFILE"

cd "$OUT"
for iso in electron-linux-"$VARIANT"-*.iso; do sha256sum "$iso" > "$iso.sha256"; done
echo "Done. ISO(s) in $OUT"
