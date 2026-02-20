#!/usr/bin/env bash
set -euo pipefail

readonly E_USAGE=64
readonly E_PRECHECK=65
readonly E_VERIFY=70

usage() {
  cat <<USAGE
Usage: release-verify.sh --assets-dir <dir>

Options:
  --assets-dir <dir>  Directory containing release artifacts, SHA256SUMS, and SHA256SUMS.asc
USAGE
}

die() {
  local code="$1"
  shift
  printf '[ERROR] %s\n' "$*" >&2
  exit "$code"
}

ensure_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "$E_PRECHECK" "missing command: $cmd"
}

build_artifact_list() {
  local assets_dir="$1"
  local out_file="$2"

  (
    cd "$assets_dir"
    find . -type f \
      ! -name 'SHA256SUMS' \
      ! -name 'SHA256SUMS.asc' \
      -print \
      | sed 's#^\./##' \
      | LC_ALL=C sort
  ) >"$out_file"
}

build_checksum_manifest_list() {
  local checksum_path="$1"
  local out_file="$2"
  : >"$out_file"

  local line rel
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    if [[ ! "$line" =~ ^[0-9A-Fa-f]{64}[[:space:]]+.+$ ]]; then
      die "$E_PRECHECK" "invalid checksum line format in: $checksum_path"
    fi
    rel="$(sed -E 's/^[0-9A-Fa-f]{64}[[:space:]]+//' <<<"$line")"
    printf '%s\n' "$rel" >>"$out_file"
  done <"$checksum_path"

  LC_ALL=C sort -o "$out_file" "$out_file"
}

verify_checksum_values() {
  local assets_dir="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    if (cd "$assets_dir" && sha256sum -c SHA256SUMS >/dev/null); then
      return 0
    fi
    return 1
  fi
  if command -v shasum >/dev/null 2>&1; then
    if (cd "$assets_dir" && shasum -a 256 -c SHA256SUMS >/dev/null); then
      return 0
    fi
    return 1
  fi
  die "$E_PRECHECK" "missing command: sha256sum (or shasum)"
}

main() {
  local assets_dir=""

  while (( $# > 0 )); do
    case "$1" in
      --assets-dir)
        assets_dir="${2:-}"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        usage >&2
        die "$E_USAGE" "unknown option: $1"
        ;;
    esac
  done

  [[ -n "$assets_dir" ]] || die "$E_USAGE" "--assets-dir is required"
  [[ -d "$assets_dir" ]] || die "$E_PRECHECK" "assets dir not found: $assets_dir"

  local checksum_path signature_path
  checksum_path="$assets_dir/SHA256SUMS"
  signature_path="$assets_dir/SHA256SUMS.asc"

  [[ -f "$checksum_path" ]] || die "$E_PRECHECK" "missing checksum file: $checksum_path"
  [[ -f "$signature_path" ]] || die "$E_PRECHECK" "missing signature file: $signature_path"

  ensure_cmd gpg
  if ! gpg --verify "$signature_path" "$checksum_path" >/dev/null 2>&1; then
    die "$E_VERIFY" "signature verification failed for: $checksum_path"
  fi

  local actual_list expected_list
  actual_list="$(mktemp)"
  expected_list="$(mktemp)"

  build_artifact_list "$assets_dir" "$actual_list"
  if [[ ! -s "$actual_list" ]]; then
    rm -f "$actual_list" "$expected_list"
    die "$E_PRECHECK" "no artifacts found in: $assets_dir"
  fi

  build_checksum_manifest_list "$checksum_path" "$expected_list"
  if ! diff -u "$expected_list" "$actual_list" >/dev/null 2>&1; then
    rm -f "$actual_list" "$expected_list"
    die "$E_VERIFY" "artifact set does not match SHA256SUMS entries"
  fi

  rm -f "$actual_list" "$expected_list"

  if ! verify_checksum_values "$assets_dir"; then
    die "$E_VERIFY" "checksum verification failed for: $checksum_path"
  fi

  printf '[INFO] signature and checksums verified: %s\n' "$assets_dir"
}

main "$@"
