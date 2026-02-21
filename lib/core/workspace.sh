#!/usr/bin/env bash

if [[ -n "${OSSETUP_WORKSPACE_SH:-}" ]]; then
  return 0
fi
OSSETUP_WORKSPACE_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"

workspace_config_filename() {
  printf '%s\n' '.ossetup-workspace.json'
}

resolve_abs_path() {
  local input="$1"
  if [[ "$input" = /* ]]; then
    printf '%s\n' "$input"
    return 0
  fi
  printf '%s\n' "$(pwd)/$input"
}

resolve_abs_dir() {
  local input="$1"
  if [[ "$input" = /* ]]; then
    input="$input"
  else
    input="$(pwd)/$input"
  fi
  if [[ -d "$input" ]]; then
    (cd -P "$input" && pwd -P)
    return 0
  fi

  local base
  base="$(dirname "$input")"
  local name
  name="$(basename "$input")"
  if [[ -d "$base" ]]; then
    printf '%s/%s\n' "$(cd -P "$base" && pwd -P)" "$name"
    return 0
  fi

  return 1
}

find_workspace_config() {
  local dir="${OSSETUP_WORKSPACE_CWD:-$PWD}"
  local name
  name="$(workspace_config_filename)"

  while true; do
    if [[ -f "$dir/$name" ]]; then
      printf '%s\n' "$dir/$name"
      return 0
    fi

    if [[ "$dir" == "/" ]]; then
      break
    fi
    dir="$(dirname "$dir")"
  done

  return 1
}

workspace_config_path() {
  if [[ -n "${OSSETUP_WORKSPACE_FILE:-}" ]]; then
    local explicit
    explicit="$(resolve_abs_path "$OSSETUP_WORKSPACE_FILE")"
    [[ -f "$explicit" ]] || die "$E_PRECHECK" "workspace config missing: $explicit"
    printf '%s\n' "$explicit"
    return 0
  fi

  local discovered
  discovered="$(find_workspace_config || true)"
  if [[ -n "$discovered" ]]; then
    printf '%s\n' "$discovered"
    return 0
  fi

  die "$E_PRECHECK" "workspace config is required; create .ossetup-workspace.json in your personal repo"
}

init_workspace_context() {
  local ws_file
  ws_file="$(workspace_config_path)"

  [[ -f "$ws_file" ]] || die "$E_PRECHECK" "workspace config missing: $ws_file"
  command -v jq >/dev/null 2>&1 || die "$E_PRECHECK" "workspace config requires jq: $ws_file"

  local mode
  mode="$(jq -r '.mode // empty' "$ws_file")"
  [[ -n "$mode" ]] || die "$E_PRECHECK" "workspace config missing mode: $ws_file (expected: personal-only)"

  case "$mode" in
    personal-only)
      ;;
    personal-overrides)
      mode="personal-only"
      ;;
    *)
      die "$E_PRECHECK" "workspace config has unsupported mode: $mode (expected: personal-only)"
      ;;
  esac

  local core_repo_path
  core_repo_path="$(jq -r '.core_repo_path // empty' "$ws_file")"
  [[ -n "$core_repo_path" ]] || die "$E_PRECHECK" "workspace config missing core_repo_path: $ws_file"

  local user_id
  user_id="$(jq -r '.user_id // empty' "$ws_file")"
  [[ -n "$user_id" ]] || die "$E_PRECHECK" "workspace config missing user_id: $ws_file"

  local personal_root core_root
  personal_root="$(cd -P "$(dirname "$ws_file")" && pwd -P)"

  if [[ "$core_repo_path" = /* ]]; then
    core_root="$core_repo_path"
  else
    core_root="$personal_root/$core_repo_path"
  fi

  core_root="$(resolve_abs_dir "$core_root")" || die "$E_PRECHECK" "cannot resolve core repo path: $core_repo_path"
  [[ -d "$core_root" ]] || die "$E_PRECHECK" "core repo path not found: $core_root"

  set_workspace_roots "$mode" "$core_root" "$personal_root" "$user_id"
  export OSSETUP_WORKSPACE_FILE_RESOLVED="$ws_file"
}
