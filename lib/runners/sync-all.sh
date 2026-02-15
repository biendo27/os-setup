#!/usr/bin/env bash

if [[ -n "${OSSETUP_RUNNER_SYNC_ALL_SH:-}" ]]; then
  return 0
fi
OSSETUP_RUNNER_SYNC_ALL_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/runners/sync.sh"
source "$OSSETUP_ROOT/lib/providers/state-export.sh"

run_sync_all() {
  local mode="preview"
  local target="auto"

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
      --target)
        target="${2:-}"
        shift 2
        ;;
      *)
        die "$E_USAGE" "unknown sync-all option: $1"
        ;;
    esac
  done

  local resolved_target
  resolved_target="$(detect_target "$target")"

  if [[ "$mode" == "preview" ]]; then
    run_sync --preview
  else
    run_sync --apply
  fi

  export_state_for_target "$resolved_target" "$mode"
  info "sync-all ${mode^^} complete target=$resolved_target"
}
