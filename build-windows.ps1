# Build Electron Linux on Windows with Docker Desktop (runs archiso in an Arch container).
# Usage:  .\build-windows.ps1 -Variant desktop
param([ValidateSet("minimal","desktop")][string]$Variant = "minimal")

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker Desktop is required: https://www.docker.com/products/docker-desktop/"; exit 1
}
docker run --rm --privileged -v "${PSScriptRoot}:/src" archlinux:latest bash -c `
  "pacman -Syu --noconfirm archiso grub && BUILD_DIR=/tmp/build bash /src/build.sh $Variant"
if ($?) { Write-Host "ISO written to $(Join-Path $PSScriptRoot 'out')" }
