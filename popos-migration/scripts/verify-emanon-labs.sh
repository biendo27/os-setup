#!/usr/bin/env bash
set -euo pipefail

DEVICE="/dev/nvme1n1p1"
MOUNT_POINT="/home/emanon/emanon_labs"
OWNER_USER="emanon"
SHARE_GROUP="labshare"

usage() {
  cat <<USAGE
Usage: $0 [options]

Options:
  --device <path>         Expected source device (default: ${DEVICE})
  --mount-point <path>    Expected mount point (default: ${MOUNT_POINT})
  --owner <user>          Expected owner user (default: ${OWNER_USER})
  --group <group>         Expected shared group (default: ${SHARE_GROUP})
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

failures=0

pass() { echo "[PASS] $1"; }
fail() { echo "[FAIL] $1"; failures=$((failures + 1)); }
warn() { echo "[WARN] $1"; }

if findmnt -T "${MOUNT_POINT}" >/dev/null 2>&1; then
  actual_source="$(findmnt -T "${MOUNT_POINT}" -no SOURCE)"
  actual_fstype="$(findmnt -T "${MOUNT_POINT}" -no FSTYPE)"
  if [[ "${actual_source}" == "${DEVICE}" ]]; then
    pass "Mount source is ${DEVICE}"
  else
    fail "Mount source mismatch: expected ${DEVICE}, got ${actual_source}"
  fi
  if [[ "${actual_fstype}" == "ext4" ]]; then
    pass "Filesystem type is ext4"
  else
    fail "Filesystem type mismatch: expected ext4, got ${actual_fstype}"
  fi
else
  fail "Mount point is not mounted: ${MOUNT_POINT}"
fi

if [[ -d "${MOUNT_POINT}" ]]; then
  perms="$(stat -c '%a' "${MOUNT_POINT}")"
  owner="$(stat -c '%U' "${MOUNT_POINT}")"
  group="$(stat -c '%G' "${MOUNT_POINT}")"

  [[ "${owner}" == "${OWNER_USER}" ]] && pass "Owner user is ${OWNER_USER}" || fail "Owner user mismatch: ${owner}"
  [[ "${group}" == "${SHARE_GROUP}" ]] && pass "Group is ${SHARE_GROUP}" || fail "Group mismatch: ${group}"

  if [[ "${perms}" =~ ^27[0-7][0-7]$ ]]; then
    pass "Directory mode has setgid (${perms})"
  else
    fail "Directory mode should include setgid (expected 27xx, got ${perms})"
  fi
else
  fail "Mount point directory does not exist: ${MOUNT_POINT}"
fi

if id "${OWNER_USER}" >/dev/null 2>&1; then
  if id -nG "${OWNER_USER}" | tr ' ' '\n' | grep -Fxq "${SHARE_GROUP}"; then
    pass "${OWNER_USER} is in group ${SHARE_GROUP}"
  else
    fail "${OWNER_USER} is not in group ${SHARE_GROUP}"
  fi
else
  fail "Owner user does not exist: ${OWNER_USER}"
fi

if command -v getfacl >/dev/null 2>&1; then
  acl_line="$(getfacl -cp "${MOUNT_POINT}" 2>/dev/null | grep -E '^default:group:'"${SHARE_GROUP}"':rwx' || true)"
  if [[ -n "${acl_line}" ]]; then
    pass "Default ACL exists for group ${SHARE_GROUP}"
  else
    warn "Default ACL for ${SHARE_GROUP} not found"
  fi
else
  warn "getfacl not installed; ACL check skipped"
fi

if [[ ${failures} -gt 0 ]]; then
  echo
  echo "Verification finished with ${failures} failure(s)."
  exit 1
fi

echo
echo "Verification passed."
