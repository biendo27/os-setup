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

  local target_legacy_manifest target_layer_manifest core_layer_manifest
  target_legacy_manifest="$(target_manifest_path "$target")"
  target_layer_manifest="$(layers_target_manifest_path "$target")"
  core_layer_manifest="$(layers_core_manifest_path)"

  local f
  for f in \
    "$(profile_manifest_path default)" \
    "$(dotfiles_manifest_path)" \
    "$(secrets_manifest_path)"
  do
    if [[ -f "$f" ]]; then
      info "manifest ok: ${f#$OSSETUP_ROOT/}"
    else
      die "$E_PRECHECK" "manifest missing: $f"
    fi
  done

  if [[ -f "$core_layer_manifest" && -f "$target_layer_manifest" ]]; then
    info "manifest ok: ${core_layer_manifest#$OSSETUP_ROOT/}"
    info "manifest ok: ${target_layer_manifest#$OSSETUP_ROOT/}"
  elif [[ -f "$target_legacy_manifest" ]]; then
    info "manifest ok: ${target_legacy_manifest#$OSSETUP_ROOT/}"
  else
    die "$E_PRECHECK" "target manifest missing: $target_legacy_manifest and $target_layer_manifest"
  fi

  ensure_cmd jq
  ensure_cmd find
  ensure_cmd cp
  check_global_shim "$require_global"
  info "doctor complete"
}
