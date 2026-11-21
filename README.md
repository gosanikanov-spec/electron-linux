# Electron Linux

A clean, minimal, **Arch-based** Linux distribution built with [archiso](https://wiki.archlinux.org/title/Archiso).

- **Nothing you didn't ask for**: just the base system, NetworkManager, and a few essentials
- **Rolling release**: straight from the official Arch repos, no custom repo to trust
- **No telemetry**
- **Lean image**: docs and non-English translations aren't installed
- **Boots anywhere**: UEFI and BIOS, from USB or a VM, with Intel/AMD microcode and firmware included
- **Installs with `archinstall`**: guided install to disk from the live session

## Variants

| Variant   | Contents                                                              |
|-----------|-----------------------------------------------------------------------|
| `minimal` | Console system: NetworkManager (`nmtui`), SSH, htop, nano, archinstall |
| `desktop` | Minimal plus **Hyprland** (Wayland), Waybar, Wofi, Kitty, PipeWire, Firefox |

### Hyprland keys (desktop)

| Keys              | Action               |
|-------------------|----------------------|
| `Super + Enter`   | Terminal (kitty)     |
| `Super + D`       | App launcher (wofi)  |
| `Super + B` / `E` | Firefox / Files      |
| `Super + Q`       | Close window         |
| `Super + F` / `V` | Fullscreen / Float   |
| `Super + 1–5`     | Switch workspace (`+ Shift` moves the window) |
| `Print`           | Screenshot region to clipboard |
| `Super + Shift + M` | Log out            |

Edit `~/.config/hypr/hyprland.conf` to customize. Hyprland needs 3D acceleration: in a VM,
turn on 3D (VMware, VirtualBox with VMSVGA, or QEMU with `virtio-vga-gl`).

## Apple Silicon Macs (UTM)

For Apple Silicon Macs (any M-series chip) there's a native **ARM64** build based on [Arch Linux ARM](https://archlinuxarm.org/).
It's a ready-to-boot disk image (`electron-linux-<variant>-aarch64.qcow2`) rather than an ISO.
It's an installed system, so changes you make inside the VM are kept.

1. Download the `electron-linux-desktop-arm64-utm` artifact from the latest Actions run and unzip it.
2. In [UTM](https://mac.getutm.app/), click **+** → **Virtualize** → **Linux**. Leave the ISO/boot image empty.
   Give it 4 GB+ RAM and 4 CPU cores, then **Save**.
3. Right-click the VM → **Edit**:
   - **Drives:** delete the empty drive UTM created, then **New → Import** and pick the `.qcow2` file (interface: VirtIO).
   - **Display:** choose `virtio-gpu-gl-pci` (**GPU Supported**). Hyprland needs it.
4. Start the VM. It boots straight into Hyprland as `live` (no password).

To get more disk space, resize the drive in UTM and then grow the root partition inside the VM.

## Building

### GitHub Actions (nothing to install locally)
Every push to `main` builds both ISOs. Open **Actions**, pick the latest run, and download the
`electron-linux-minimal` / `electron-linux-desktop` artifacts. Pushing a tag like `v1.0` also
attaches the ISOs to a GitHub Release.

### Windows (Docker Desktop)
```powershell
.\build-windows.ps1 -Variant desktop
```

### Arch Linux
```bash
sudo pacman -S archiso grub
sudo ./build.sh minimal      # or: desktop
```

The ISO and its `.sha256` checksum are written to `out/`.

### ARM64 image (any aarch64 Linux host, e.g. Ubuntu on ARM)
```bash
sudo apt install arch-install-scripts libarchive-tools gdisk dosfstools e2fsprogs qemu-utils
sudo ./build-arm.sh desktop      # or: minimal
```

## Using it

- **USB:** flash with Rufus (DD mode), balenaEtcher, or `dd`. In a **VM**, boot the ISO directly (turn Secure Boot off).
- You're logged in automatically as `live` (no password, passwordless `sudo`).
- To install to disk, run `sudo archinstall`. On the desktop variant, open a terminal first (`Super + Enter`).

## Layout

```
build.sh                       Main build script (layers this repo over archiso's 'baseline' profile)
profile/packages/base.txt      Packages in every variant
profile/packages/<variant>.txt Extra packages per variant
profile/airootfs/common/       Files copied into the live system (mirrors /)
profile/airootfs/desktop/      Extra files for the desktop variant
.github/workflows/build.yml    CI build for both ISOs
```

To add a package, put it in a `profile/packages/*.txt` file. To add a file to the system,
place it under `profile/airootfs/common/` at the path it should have.
