#!/usr/bin/env bash

if [[ -n "${OSSETUP_RUNNER_DOCTOR_SH:-}" ]]; then
  return 0
fi
OSSETUP_RUNNER_DOCTOR_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/core/manifest.sh"
source "$OSSETUP_ROOT/lib/providers/global-shim.sh"

doctor_log_path() {
  local path="$1"
  local root
  for root in "$(ossetup_personal_root)" "$(ossetup_core_root)" "$OSSETUP_ROOT"; do
    if path_is_within "$path" "$root"; then
      printf '%s\n' "${path#$root/}"
      return 0
    fi
  done
  printf '%s\n' "$path"
}

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

  if is_personal_workspace_mode; then
    info "workspace mode: personal-overrides"
    info "workspace file: ${OSSETUP_WORKSPACE_FILE_RESOLVED:-unknown}"
    info "core repo: $(ossetup_core_root)"
    info "personal repo: $(ossetup_personal_root)"
  else
    info "workspace mode: single-repo"
  fi

  info "target: $target"

  local target_layer_manifest core_layer_manifest
  target_layer_manifest="$(layers_target_manifest_path "$target")"
  core_layer_manifest="$(layers_core_manifest_path)"

  local f
  for f in \
    "$(profile_manifest_path default)" \
    "$(dotfiles_manifest_path)" \
    "$(secrets_manifest_path)"
  do
    if [[ -f "$f" ]]; then
      info "manifest ok: $(doctor_log_path "$f")"
    else
      die "$E_PRECHECK" "manifest missing: $f"
    fi
  done

  if [[ -f "$core_layer_manifest" && -f "$target_layer_manifest" ]]; then
    info "manifest ok: $(doctor_log_path "$core_layer_manifest")"
    info "manifest ok: $(doctor_log_path "$target_layer_manifest")"
  else
    die "$E_PRECHECK" "layered manifests required for target=$target (missing: $core_layer_manifest and/or $target_layer_manifest)"
  fi

  ensure_cmd jq
  ensure_cmd find
  ensure_cmd cp
  check_global_shim "$require_global"
  info "doctor complete"
}
