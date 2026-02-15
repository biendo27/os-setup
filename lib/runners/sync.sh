#!/usr/bin/env bash

if [[ -n "${OSSETUP_RUNNER_SYNC_SH:-}" ]]; then
  return 0
fi
OSSETUP_RUNNER_SYNC_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/providers/dotfiles.sh"
source "$OSSETUP_ROOT/lib/providers/functions.sh"

run_sync() {
  local mode="preview"

  while (( $# > 0 )); do
    case "$1" in
      --preview)
        mode="preview"
        shift
        ;;
      --apply)
        mode="apply"
        shift
        ;;
      *)
        die "$E_USAGE" "unknown sync option: $1"
        ;;
    esac
  done

  ensure_cmd jq
  acquire_lock

  OSSETUP_SYNC_DOTFILES_CHANGED=0
  OSSETUP_SYNC_FUNCTIONS_CHANGED=0
  sync_dotfiles "$mode"
  sync_functions "$mode"

  local changed_dotfiles changed_functions
  changed_dotfiles="${OSSETUP_SYNC_DOTFILES_CHANGED:-0}"
  changed_functions="${OSSETUP_SYNC_FUNCTIONS_CHANGED:-0}"

  if [[ "$mode" == "preview" ]]; then
    info "PREVIEW complete changed=$((changed_dotfiles + changed_functions))"
  else
    info "APPLY complete changed=$((changed_dotfiles + changed_functions))"
  fi
}
