#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${BASE_DIR}/reports/${STAMP}"
REPORT_FILE="${OUT_DIR}/system-report.txt"

mkdir -p "${OUT_DIR}"

section() {
  local title="$1"
  {
    echo "===== ${title} ====="
    echo
  } >> "${REPORT_FILE}"
}

capture_cmd() {
  local title="$1"
  local cmd="$2"
  {
    echo "$ ${cmd}"
    bash -lc "${cmd}" 2>&1 || true
    echo
  } >> "${REPORT_FILE}"
}

section "Host and OS"
capture_cmd "host" "uname -a"
capture_cmd "os-release" "cat /etc/os-release"
capture_cmd "hostnamectl" "hostnamectl"
capture_cmd "uptime" "uptime"

section "Storage Layout"
capture_cmd "lsblk" "lsblk -o NAME,TYPE,SIZE,FSTYPE,LABEL,UUID,FSAVAIL,FSUSE%,MOUNTPOINTS"
capture_cmd "df" "df -hT"
capture_cmd "findmnt root" "findmnt -T / -o TARGET,SOURCE,FSTYPE,OPTIONS"
capture_cmd "findmnt home" "findmnt -T /home -o TARGET,SOURCE,FSTYPE,OPTIONS"
capture_cmd "findmnt opt" "findmnt -T /opt -o TARGET,SOURCE,FSTYPE,OPTIONS"
capture_cmd "findmnt efi" "findmnt -T /boot/efi -o TARGET,SOURCE,FSTYPE,OPTIONS"
capture_cmd "fstab" "cat /etc/fstab"

section "Boot and Firmware"
capture_cmd "kernel cmdline" "cat /proc/cmdline"
capture_cmd "secure boot" "mokutil --sb-state"
capture_cmd "efi boot entries" "efibootmgr -v"

section "User and Permissions"
capture_cmd "id" "id"
capture_cmd "passwd entry" "getent passwd \"${USER}\""
capture_cmd "groups" "groups \"${USER}\""
capture_cmd "home perms" "stat -c '%n %U:%G %a' /home /home/${USER}"

section "Packages"
capture_cmd "apt manual count" "apt-mark showmanual | wc -l"
capture_cmd "snap list" "snap list"
capture_cmd "flatpak list" "flatpak list --app"

section "Drivers"
capture_cmd "ubuntu-drivers devices" "ubuntu-drivers devices"
capture_cmd "nvidia package" "dpkg -l | rg -i 'nvidia-driver'"

apt-mark showmanual | sort > "${OUT_DIR}/apt-manual.txt" || true
snap list > "${OUT_DIR}/snap-list.txt" || true
flatpak list --app > "${OUT_DIR}/flatpak-apps.txt" || true

cat > "${OUT_DIR}/README.txt" <<EOT
Generated at: ${STAMP}
Path: ${OUT_DIR}

Files:
- system-report.txt
- apt-manual.txt
- snap-list.txt
- flatpak-apps.txt
EOT

echo "Export complete: ${OUT_DIR}"
