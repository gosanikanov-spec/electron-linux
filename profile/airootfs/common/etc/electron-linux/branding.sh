#!/bin/sh
# Re-applied by a pacman hook whenever the 'filesystem' package installs/upgrades.
cat > /usr/lib/os-release <<'EOF'
NAME="Electron Linux"
PRETTY_NAME="Electron Linux"
ID=electron
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;0;170;255"
HOME_URL="https://github.com/gosanikanov-spec/electron-linux"
LOGO=archlinux-logo
EOF
printf 'Electron Linux \\r (\\l)\n\n' > /etc/issue
