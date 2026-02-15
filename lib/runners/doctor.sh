#!/usr/bin/env bash

if [[ -n "${OSSETUP_RUNNER_DOCTOR_SH:-}" ]]; then
  return 0
fi
OSSETUP_RUNNER_DOCTOR_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/core/manifest.sh"
source "$OSSETUP_ROOT/lib/providers/global-shim.sh"

run_doctor() {
  local require_global=0

  while (( $# > 0 )); do
    case "$1" in
      --require-global)
        require_global=1
        shift
        ;;
      *)
        die "$E_USAGE" "unknown doctor option: $1"
        ;;
    esac
  done

  local target
  target="$(detect_target auto)"

  info "target: $target"

  local f
  for f in \
    "$(profile_manifest_path default)" \
    "$(target_manifest_path "$target")" \
    "$(dotfiles_manifest_path)" \
    "$(secrets_manifest_path)"
  do
    if [[ -f "$f" ]]; then
      info "manifest ok: ${f#$OSSETUP_ROOT/}"
    else
      die "$E_PRECHECK" "manifest missing: $f"
    fi
  done

  ensure_cmd jq
  ensure_cmd find
  ensure_cmd cp
  check_global_shim "$require_global"
  info "doctor complete"
}
