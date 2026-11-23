#!/usr/bin/env bash
# Builds AUR packages (default: the Calamares installer) into a local pacman repo at ./repo,
# which build.sh then uses for the desktop ISO. AUR dependencies are resolved recursively.
# Usage (on Arch, as root):  ./build-aur.sh [package ...]
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
SRC="$(cd "$(dirname "$0")" && pwd)"
REPO="$SRC/repo"
WORK="${AUR_WORK_DIR:-/tmp/aur-build}"
PKGS=("$@"); [[ ${#PKGS[@]} -gt 0 ]] || PKGS=(calamares)

pacman -S --needed --noconfirm base-devel git jq sudo curl

# makepkg refuses to run as root: build as an unprivileged user with passwordless sudo
id builder &>/dev/null || useradd -m builder
echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/90-builder
chmod 440 /etc/sudoers.d/90-builder

rm -rf "$WORK"; mkdir -p "$WORK" "$REPO"; chown builder: "$WORK"

declare -A SEEN
in_repos()  { pacman -Sp --print-format %n "$1" &>/dev/null || pacman -Qq "$1" &>/dev/null; }
aur_base()  { curl -fsSL "https://aur.archlinux.org/rpc/v5/info?arg%5B%5D=$1" | jq -r '.results[0].PackageBase // empty'; }

build() {
  local name="$1" base d
  [[ -n "${SEEN[$name]:-}" ]] && return 0
  SEEN[$name]=1
  base="$(aur_base "$name")"
  [[ -n "$base" ]] || { echo "ERROR: '$name' is in neither the Arch repos nor the AUR"; exit 1; }
  [[ -d "$WORK/$base" ]] || sudo -u builder git clone -q "https://aur.archlinux.org/$base.git" "$WORK/$base"

  # Build any AUR-only dependencies first
  for d in $(sed -n 's/^[[:space:]]*\(depends\|makedepends\|checkdepends\)\(_x86_64\)\? = //p' "$WORK/$base/.SRCINFO"); do
    d="${d%%[<>=]*}"
    in_repos "$d" || build "$d"
  done

  echo ">> Building $base (AUR)"
  (cd "$WORK/$base" && sudo -u builder makepkg -si --noconfirm --needed --skippgpcheck --nocheck)
}

for p in "${PKGS[@]}"; do build "$p"; done

find "$WORK" -name '*.pkg.tar.zst' ! -name '*-debug-*' -exec cp {} "$REPO/" \;
rm -f "$REPO"/electron-local.*
repo-add "$REPO/electron-local.db.tar.gz" "$REPO"/*.pkg.tar.zst
echo "Local repo ready: $REPO"
ls -la "$REPO"
