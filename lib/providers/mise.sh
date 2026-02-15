#!/usr/bin/env bash

if [[ -n "${OSSETUP_PROVIDER_MISE_SH:-}" ]]; then
  return 0
fi
OSSETUP_PROVIDER_MISE_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"

install_mise() {
  local target="$1"
  local dry_run="$2"

  if command -v mise >/dev/null 2>&1; then
    info "mise already installed"
    return 0
  fi

  if [[ "$dry_run" == "1" ]]; then
    info "dry-run install mise for $target"
    return 0
  fi

  case "$target" in
    macos)
      command -v brew >/dev/null 2>&1 || die "$E_INSTALL" "brew is required to install mise on macos"
      brew install mise
      ;;
    linux-debian)
      curl -fsSL https://mise.jdx.dev/install.sh | sh
      export PATH="$OSSETUP_HOME/.local/bin:$PATH"
      ;;
    *)
      die "$E_TARGET" "unsupported target for mise: $target"
      ;;
  esac
}

install_mise_tools() {
  local dry_run="$1"

  if [[ "$dry_run" == "1" ]]; then
    info "dry-run mise install"
    return 0
  fi

  if ! command -v mise >/dev/null 2>&1; then
    warn "mise not found; skipping tool installation"
    return 0
  fi

  # shellcheck disable=SC1090
  eval "$(mise activate bash)"
  mise install
}
