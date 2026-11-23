#!/bin/bash
# Runs inside the freshly copied system (before the user is created):
# turns the live-ISO copy into a normal installed system.
set -u

# Live user and live-only settings
userdel -r live 2>/dev/null || { userdel live 2>/dev/null; rm -rf /home/live; }
groupdel autologin 2>/dev/null || true
rm -f  /etc/sudoers.d/00-live
rm -rf /etc/systemd/system/getty@tty1.service.d
rm -f  /usr/share/applications/electron-install.desktop
rm -f  /etc/systemd/journald.conf.d/volatile-storage.conf
rm -f  /etc/systemd/logind.conf.d/do-not-suspend.conf

# Login screen instead of live autologin
cat > /etc/greetd/config.toml <<'CONF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --asterisks --cmd Hyprland"
user = "greeter"
CONF

cat > /etc/motd <<'CONF'

  Welcome to Electron Linux.
    Update:            sudo pacman -Syu
    Install software:  sudo pacman -S <package>
    Wi-Fi/network:     nmtui

CONF

# Normal (non-archiso) initramfs setup
rm -f /etc/mkinitcpio.conf.d/archiso.conf
cat > /etc/mkinitcpio.d/linux.preset <<'CONF'
# mkinitcpio preset file for the 'linux' package
ALL_kver="/boot/vmlinuz-linux"
PRESETS=('default' 'fallback')
default_image="/boot/initramfs-linux.img"
fallback_image="/boot/initramfs-linux-fallback.img"
fallback_options="-S autodetect"
CONF

# Bootloader branding and dual-boot detection (e.g. Windows)
if [ -f /etc/default/grub ]; then
  sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="Electron"/' /etc/default/grub
  sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
  grep -q '^GRUB_DISABLE_OS_PROBER=' /etc/default/grub || echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
fi

# Package signing keys for the installed system
pacman-key --init
pacman-key --populate archlinux

# Remove the live/installer-only packages, then anything only they needed
for p in mkinitcpio-archiso calamares; do
  pacman -Qq "$p" &>/dev/null && pacman -Rdd --noconfirm "$p"
done
orphans="$(pacman -Qdtq 2>/dev/null || true)"
[ -n "$orphans" ] && pacman -Rns --noconfirm $orphans

exit 0
