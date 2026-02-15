#!/usr/bin/env bash
set -euo pipefail

DEVICE="/dev/nvme1n1p1"
MOUNT_POINT="/home/emanon/emanon_labs"
OWNER_USER="emanon"
SHARE_GROUP="labshare"
FS_LABEL="emanon_labs"
FORMAT_DEVICE=0

usage() {
  cat <<USAGE
Usage: sudo $0 [options]

Options:
  --device <path>         Block device to mount (default: ${DEVICE})
  --mount-point <path>    Mount point (default: ${MOUNT_POINT})
  --owner <user>          Owner user for mountpoint (default: ${OWNER_USER})
  --group <group>         Shared group (default: ${SHARE_GROUP})
  --label <label>         ext4 label to set (default: ${FS_LABEL})
  --format                Format device as ext4 before configuring (destructive)
  -h, --help              Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      DEVICE="$2"
      shift 2
      ;;
    --mount-point)
      MOUNT_POINT="$2"
      shift 2
      ;;
    --owner)
      OWNER_USER="$2"
      shift 2
      ;;
    --group)
      SHARE_GROUP="$2"
      shift 2
      ;;
    --label)
      FS_LABEL="$2"
      shift 2
      ;;
    --format)
      FORMAT_DEVICE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

if [[ ! -b "${DEVICE}" ]]; then
  echo "Device not found: ${DEVICE}" >&2
  exit 1
fi

if ! getent passwd "${OWNER_USER}" >/dev/null; then
  echo "User not found: ${OWNER_USER}" >&2
  exit 1
fi

if [[ ${FORMAT_DEVICE} -eq 1 ]]; then
  echo "Formatting ${DEVICE} as ext4 label=${FS_LABEL}"
  mkfs.ext4 -F -L "${FS_LABEL}" "${DEVICE}"
fi

UUID="$(blkid -s UUID -o value "${DEVICE}" || true)"
if [[ -z "${UUID}" ]]; then
  echo "Could not read UUID for ${DEVICE}" >&2
  exit 1
fi

mkdir -p "${MOUNT_POINT}"

# Best effort label update for ext filesystems.
if command -v e2label >/dev/null 2>&1; then
  e2label "${DEVICE}" "${FS_LABEL}" || true
fi

FSTAB_LINE="UUID=${UUID} ${MOUNT_POINT} ext4 defaults,noatime,nofail 0 2"
ESCAPED_MOUNT="$(printf '%s' "${MOUNT_POINT}" | sed 's/[.[\*^$()+?{}|/]/\\&/g')"
EXISTING_LINE="$(grep -E "^[^#].*[[:space:]]${ESCAPED_MOUNT}[[:space:]]" /etc/fstab || true)"

cp /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d-%H%M%S)"

if [[ -n "${EXISTING_LINE}" ]]; then
  if grep -Eq "^[^#]*UUID=${UUID}[[:space:]]+${ESCAPED_MOUNT}[[:space:]]" <<<"${EXISTING_LINE}"; then
    echo "fstab entry already present for ${MOUNT_POINT}"
  else
    echo "Conflicting /etc/fstab entry for ${MOUNT_POINT}:" >&2
    echo "${EXISTING_LINE}" >&2
    echo "Fix /etc/fstab manually, then rerun." >&2
    exit 1
  fi
else
  echo "${FSTAB_LINE}" >> /etc/fstab
  echo "Added fstab entry: ${FSTAB_LINE}"
fi

if ! mountpoint -q "${MOUNT_POINT}"; then
  mount "${MOUNT_POINT}" || mount -a
fi

groupadd -f "${SHARE_GROUP}"
usermod -aG "${SHARE_GROUP}" "${OWNER_USER}"

chown "${OWNER_USER}:${SHARE_GROUP}" "${MOUNT_POINT}"
chmod 2770 "${MOUNT_POINT}"

if command -v setfacl >/dev/null 2>&1; then
  setfacl -m "g:${SHARE_GROUP}:rwx" "${MOUNT_POINT}"
  setfacl -d -m "g:${SHARE_GROUP}:rwx" "${MOUNT_POINT}"
else
  echo "Warning: setfacl not found. Install package 'acl' and rerun for ACL defaults." >&2
fi

echo
echo "Completed setup for ${MOUNT_POINT}"
echo "Next step for future test user:"
echo "  sudo usermod -aG ${SHARE_GROUP} <testuser>"
echo "  (logout/login required for new group to apply)"
