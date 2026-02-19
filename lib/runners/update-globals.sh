#!/usr/bin/env bash

if [[ -n "${OSSETUP_RUNNER_UPDATE_GLOBALS_SH:-}" ]]; then
  return 0
fi
OSSETUP_RUNNER_UPDATE_GLOBALS_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"

run_update_globals() {
  local dry_run=0
  local assume_yes=0
  while (( $# > 0 )); do
    case "$1" in
      --dry-run)
        dry_run=1
        shift
        ;;
      -y|--yes)
        assume_yes=1
        shift
        ;;
      -h|--help)
        cat <<USAGE
Usage: ossetup update-globals [--dry-run] [-y|--yes]

Updates global packages managed by available package managers:
  - npm       -> npm update -g
  - pnpm      -> pnpm update -g --latest
  - yarn      -> yarn global upgrade (yarn classic only)
  - pipx      -> pipx upgrade-all
  - dart pub  -> re-activate each package from dart pub global list

Options:
  --dry-run   Print actions without executing updates
  -y, --yes   Skip confirmation prompts (assume Yes)

Interactive mode:
  Prompts before each manager update using [Y/n] with default Yes.
USAGE
        return 0
        ;;
      *)
        die "$E_USAGE" "unknown update-globals option: $1"
        ;;
    esac
  done

  run_cmd() {
    if (( dry_run )); then
      info "dry-run: $*"
      return 0
    fi
    "$@"
  }

  confirm_step() {
    local prompt="$1"
    local answer=""

    if (( assume_yes || dry_run )); then
      return 0
    fi

    if [[ ! -t 0 ]]; then
      info "non-interactive stdin; default yes for: $prompt"
      return 0
    fi

    while true; do
      printf '%s [Y/n]: ' "$prompt"
      if ! IFS= read -r answer; then
        return 0
      fi
      case "${answer}" in
        ""|y|Y|yes|YES|Yes)
          return 0
          ;;
        n|N|no|NO|No)
          return 1
          ;;
        *)
          warn "please answer y or n"
          ;;
      esac
    done
  }

  local had_manager=0
  local had_failure=0

  if command -v npm >/dev/null 2>&1; then
    had_manager=1
    if confirm_step "Update npm global packages?"; then
      info "updating npm global packages"
      if ! run_cmd npm update -g; then
        warn "npm global update failed"
        had_failure=1
      fi
    else
      info "skip npm global update (user choice)"
    fi
  fi

  if command -v pnpm >/dev/null 2>&1; then
    had_manager=1
    if confirm_step "Update pnpm global packages?"; then
      info "updating pnpm global packages"
      if ! run_cmd pnpm update -g --latest; then
        warn "pnpm global update failed"
        had_failure=1
      fi
    else
      info "skip pnpm global update (user choice)"
    fi
  fi

  if command -v yarn >/dev/null 2>&1; then
    had_manager=1
    local yarn_version=""
    local yarn_major=""
    yarn_version="$(yarn --version 2>/dev/null | head -n1 || true)"
    yarn_major="$(printf '%s' "$yarn_version" | sed -n 's/^\([0-9][0-9]*\)\..*/\1/p')"

    if [[ -n "$yarn_major" ]] && (( yarn_major >= 2 )); then
      info "skip yarn global update (yarn@$yarn_version does not support 'yarn global')"
    elif confirm_step "Update yarn global packages?"; then
      info "updating yarn global packages"
      if ! run_cmd yarn global upgrade; then
        warn "yarn global update failed"
        had_failure=1
      fi
    else
      info "skip yarn global update (user choice)"
    fi
  fi

  if command -v pipx >/dev/null 2>&1; then
    had_manager=1
    if confirm_step "Update pipx global packages?"; then
      info "updating pipx global packages"
      if ! run_cmd pipx upgrade-all; then
        warn "pipx global update failed"
        had_failure=1
      fi
    else
      info "skip pipx global update (user choice)"
    fi
  fi

  if command -v dart >/dev/null 2>&1; then
    had_manager=1
    local -a dart_packages=()
    local pkg=""

    while IFS= read -r pkg; do
      [[ -n "$pkg" ]] || continue
      case "$pkg" in
        No|Package)
          continue
          ;;
      esac
      dart_packages+=("$pkg")
    done < <(dart pub global list 2>/dev/null | awk 'NF {print $1}')

    if (( ${#dart_packages[@]} == 0 )); then
      info "no dart pub global packages found"
    elif confirm_step "Update dart pub global packages?"; then
      info "updating ${#dart_packages[@]} dart pub global package(s)"
      for pkg in "${dart_packages[@]}"; do
        if ! run_cmd dart pub global activate "$pkg"; then
          warn "dart pub global activate failed for: $pkg"
          had_failure=1
        fi
      done
    else
      info "skip dart pub global update (user choice)"
    fi
  fi

  if (( ! had_manager )); then
    info "no supported global package managers found"
    return 1
  fi

  if (( had_failure )); then
    return 1
  fi

  info "update-globals complete"
}
