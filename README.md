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
| `desktop` | Minimal plus Xfce, LightDM, PipeWire audio, Firefox                    |

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
sudo pacman -S archiso
sudo ./build.sh minimal      # or: desktop
```

The ISO and its `.sha256` checksum are written to `out/`.

## Using it

- **USB:** flash with Rufus (DD mode), balenaEtcher, or `dd`. In a **VM**, boot the ISO directly (turn Secure Boot off).
- You're logged in automatically as `live` (no password, passwordless `sudo`).
- To install to disk, run `sudo archinstall`. On the desktop variant, open a terminal first.

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
