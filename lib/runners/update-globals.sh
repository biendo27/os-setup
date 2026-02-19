#!/usr/bin/env bash

if [[ -n "${OSSETUP_RUNNER_UPDATE_GLOBALS_SH:-}" ]]; then
  return 0
fi
OSSETUP_RUNNER_UPDATE_GLOBALS_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"

run_update_globals() {
  ensure_cmd mise
  ensure_cmd jq

  local -a backend_tools=()
  local tool=""

  while IFS= read -r tool; do
    [[ -n "$tool" ]] || continue
    backend_tools+=("$tool")
  done < <(mise ls --global --current --json | jq -r 'keys[] | select(test(":"))')

  if (( ${#backend_tools[@]} == 0 )); then
    info "no mise backend tools configured globally (npm:/cargo:/pipx:/...)"
    return 0
  fi

  info "updating ${#backend_tools[@]} global package tool(s) via mise"
  mise upgrade --yes "${backend_tools[@]}"

  info "refreshing mise shims"
  mise reshim

  info "update-globals complete"
}
