#!/bin/bash
# Runs inside the installed system after the user account exists, before the bootloader.
set -u

# Use the keyboard layout picked in the installer for Hyprland too
layout="$(sed -n 's/.*"XkbLayout"[[:space:]]*"\([^"]*\)".*/\1/p' /etc/X11/xorg.conf.d/00-keyboard.conf 2>/dev/null | head -n1)"
if [ -n "$layout" ]; then
  sed -i "s/^\([[:space:]]*kb_layout[[:space:]]*=\).*/\1 $layout/" /etc/skel/.config/hypr/hyprland.conf /home/*/.config/hypr/hyprland.conf 2>/dev/null || true
fi

# Build the initramfs for real hardware
mkinitcpio -P || exit 1

# Installer files aren't needed on the installed system
rm -rf /etc/calamares
exit 0
