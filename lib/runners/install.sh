#!/usr/bin/env bash

if [[ -n "${OSSETUP_RUNNER_INSTALL_SH:-}" ]]; then
  return 0
fi
OSSETUP_RUNNER_INSTALL_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/core/manifest.sh"
source "$OSSETUP_ROOT/lib/providers/packages.sh"
source "$OSSETUP_ROOT/lib/providers/dotfiles.sh"
source "$OSSETUP_ROOT/lib/providers/functions.sh"
source "$OSSETUP_ROOT/lib/providers/mise.sh"
source "$OSSETUP_ROOT/lib/providers/android-sdk.sh"
source "$OSSETUP_ROOT/lib/providers/npm.sh"
source "$OSSETUP_ROOT/lib/providers/secrets-bitwarden.sh"
source "$OSSETUP_ROOT/lib/providers/global-shim.sh"

run_install() {
  local profile="default"
  local target="auto"
  local host="auto"
  local dry_run=0

  while (( $# > 0 )); do
    case "$1" in
      --profile)
        profile="${2:-}"
        shift 2
        ;;
      --target)
        target="${2:-}"
        shift 2
        ;;
      --host)
        host="${2:-}"
        shift 2
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      *)
        die "$E_USAGE" "unknown install option: $1"
        ;;
    esac
  done

  ensure_cmd jq
  ensure_cmd find

  local profile_manifest
  profile_manifest="$(profile_manifest_path "$profile")"
  require_manifest "$profile_manifest"

  local resolved_target
  resolved_target="$(detect_target "$target")"
  if ! layers_enabled_for_target "$resolved_target"; then
    require_manifest "$(target_manifest_path "$resolved_target")"
  fi

  local resolved_host
  resolved_host="$(resolve_host_id "$host")"
  export OSSETUP_HOST_ID="$resolved_host"

  acquire_lock
  info "install profile=$profile target=$resolved_target host=$resolved_host dry-run=$dry_run"

  run_hook_dir "$OSSETUP_ROOT/hooks/pre-install.d"

  if profile_module_enabled "$profile" "packages"; then
    install_packages_for_target "$resolved_target" "$dry_run" "$resolved_host"
  fi

  if profile_module_enabled "$profile" "dotfiles"; then
    apply_dotfiles "$dry_run"
  fi

  if profile_module_enabled "$profile" "functions"; then
    apply_functions "$dry_run"
  fi

  if profile_module_enabled "$profile" "mise"; then
    install_mise "$resolved_target" "$dry_run"
    install_mise_tools "$dry_run"
  fi

  if profile_module_enabled "$profile" "android_sdk"; then
    install_android_sdk "$resolved_target" "$dry_run"
  fi

  if profile_module_enabled "$profile" "npm_globals"; then
    install_npm_globals "$resolved_target" "$dry_run" "$resolved_host"
  fi

  if profile_module_enabled "$profile" "secrets"; then
    verify_bitwarden_references "$dry_run"
  fi

  if profile_module_enabled "$profile" "global_cli"; then
    install_global_shim "$dry_run"
  fi

  run_hook_dir "$OSSETUP_ROOT/hooks/post-install.d"

  info "install complete"
}
