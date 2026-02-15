#!/usr/bin/env bash

if [[ -n "${OSSETUP_RUNNER_BOOTSTRAP_SH:-}" ]]; then
  return 0
fi
OSSETUP_RUNNER_BOOTSTRAP_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/runners/install.sh"

run_bootstrap() {
  info "bootstrap delegates to install"
  run_install "$@"
}
