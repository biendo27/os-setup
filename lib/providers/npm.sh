#!/usr/bin/env bash

if [[ -n "${OSSETUP_PROVIDER_NPM_SH:-}" ]]; then
  return 0
fi
OSSETUP_PROVIDER_NPM_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/core/manifest.sh"

setup_npm_prefix() {
  local prefix="${NPM_CONFIG_PREFIX:-$OSSETUP_HOME/.npm-global}"
  mkdir -p "$prefix/bin"
  npm config set prefix "$prefix"
  export PATH="$prefix/bin:$PATH"
}

install_npm_globals() {
  local target="$1"
  local dry_run="$2"
  mapfile -t globals < <(target_npm_globals "$target")

  if (( ${#globals[@]} == 0 )); then
    info "no npm global packages configured"
    return 0
  fi

  if [[ "$dry_run" == "1" ]]; then
    info "dry-run npm globals: ${globals[*]}"
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    warn "npm not found; skipping npm global packages"
    return 0
  fi

  setup_npm_prefix
  npm install -g "${globals[@]}"
}
