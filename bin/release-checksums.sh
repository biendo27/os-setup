#!/usr/bin/env bash
set -euo pipefail

readonly E_USAGE=64
readonly E_PRECHECK=65

usage() {
  cat <<USAGE
Usage: release-checksums.sh --assets-dir <dir> [--sign-key <key-id>] [--no-sign]

Options:
  --assets-dir <dir>  Directory containing release artifacts
  --sign-key <key-id> Optional GPG key id/fingerprint used for signing
  --no-sign           Generate SHA256SUMS only (skip GPG signature)
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

detect_hash_cmd() {
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s\n' "sha256sum"
    return
  fi
  if command -v shasum >/dev/null 2>&1; then
    printf '%s\n' "shasum"
    return
  fi
  die "$E_PRECHECK" "missing command: sha256sum (or shasum)"
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

  if [[ ! -s "$out_file" ]]; then
    die "$E_PRECHECK" "no artifacts found in: $assets_dir"
  fi
}

generate_checksums() {
  local assets_dir="$1"
  local artifact_list="$2"
  local checksum_path="$3"
  local hash_cmd="$4"

  : >"$checksum_path"
  local rel hash
  while IFS= read -r rel; do
    [[ -n "$rel" ]] || continue
    if [[ "$hash_cmd" == "sha256sum" ]]; then
      hash="$(sha256sum "$assets_dir/$rel" | awk '{print $1}')"
    else
      hash="$(shasum -a 256 "$assets_dir/$rel" | awk '{print $1}')"
    fi
    printf '%s  %s\n' "$hash" "$rel" >>"$checksum_path"
  done <"$artifact_list"
}

main() {
  local assets_dir=""
  local sign_key=""
  local no_sign=0

  while (( $# > 0 )); do
    case "$1" in
      --assets-dir)
        assets_dir="${2:-}"
        shift 2
        ;;
      --sign-key)
        sign_key="${2:-}"
        shift 2
        ;;
      --no-sign)
        no_sign=1
        shift
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

  local hash_cmd
  hash_cmd="$(detect_hash_cmd)"

  local artifact_list checksum_path signature_path
  artifact_list="$(mktemp)"
  checksum_path="$assets_dir/SHA256SUMS"
  signature_path="$assets_dir/SHA256SUMS.asc"

  build_artifact_list "$assets_dir" "$artifact_list"
  generate_checksums "$assets_dir" "$artifact_list" "$checksum_path" "$hash_cmd"
  rm -f "$artifact_list"

  if (( no_sign == 1 )); then
    rm -f "$signature_path"
    printf '[INFO] generated checksums only: %s\n' "$checksum_path"
    return 0
  fi

  ensure_cmd gpg

  local -a gpg_cmd
  gpg_cmd=(gpg --batch --yes --armor --detach-sign --output "$signature_path")
  if [[ -n "$sign_key" ]]; then
    gpg_cmd+=(--local-user "$sign_key")
  fi
  gpg_cmd+=("$checksum_path")

  if ! "${gpg_cmd[@]}"; then
    die "$E_PRECHECK" "gpg signing failed for: $checksum_path"
  fi

  printf '[INFO] generated checksums: %s\n' "$checksum_path"
  printf '[INFO] generated signature: %s\n' "$signature_path"
}

main "$@"
