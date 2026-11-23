A clean, minimal, Arch-based Linux. No bloat, no telemetry, rolling updates from the official repos.

## Which file do I download?

| Version | Hardware | File |
|---|---|---|
| **PC Desktop** (Hyprland) | Windows/Linux PC, Intel or AMD | `electron-linux-desktop-…-x86_64.iso` |
| **PC Minimal** (console) | Windows/Linux PC, Intel or AMD | `electron-linux-minimal-…-x86_64.iso` |
| **Mac Desktop** (Hyprland) | Any Apple Silicon Mac (M-series) in UTM | `electron-linux-desktop-aarch64.qcow2` |
| **Mac Minimal** (console) | Any Apple Silicon Mac (M-series) in UTM | `electron-linux-minimal-aarch64.qcow2` |

Each file has a matching `.sha256` checksum.

## PC (ISO): try it without installing
1. Flash the ISO to a USB stick with Rufus (DD mode) or balenaEtcher, or boot it in VMware Workstation Pro with 3D acceleration on.
2. Boot from the stick (Secure Boot off). Nothing on your PC is changed.
3. To install it permanently: on the Desktop ISO press **Super + I** to open the graphical installer. On the Minimal ISO, run `sudo archinstall`.

## Mac (UTM)
1. In UTM, click **+** → **Virtualize** → **Linux** and leave the ISO empty. Give it 4 GB RAM and 4 cores, then save.
2. **Edit** → **Drives**: delete the empty drive, then **New → Import** the `.qcow2`.
3. **Display:** choose `virtio-gpu-gl-pci` (GPU Supported), then start the VM.

> If a file is split into `.part00`, `.part01`, …, download all the parts and join them in Terminal:
> `cat electron-linux-desktop-aarch64.qcow2.part* > electron-linux-desktop-aarch64.qcow2`

## Desktop keys
`Super + Enter` terminal · `Super + D` apps · `Super + B` Firefox · `Super + Q` close · `Super + 1–5` workspaces

Login: user `live`, no password.
