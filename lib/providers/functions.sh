#!/usr/bin/env bash

if [[ -n "${OSSETUP_PROVIDER_FUNCTIONS_SH:-}" ]]; then
  return 0
fi
OSSETUP_PROVIDER_FUNCTIONS_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/core/manifest.sh"

apply_functions() {
  local dry_run="$1"
  local repo_rel home_dir personal_dir
  repo_rel="$(function_sync_repo_dir)"
  personal_dir="$(repo_path_in_personal "$repo_rel")"
  home_dir="$(expand_home_path "$(function_sync_home_dir)")"

  if [[ "$dry_run" == "1" ]]; then
    info "dry-run functions: $repo_rel -> $home_dir"
    return 0
  fi

  local merged_dir
  merged_dir="$(mktemp -d)"
  if [[ -d "$personal_dir" ]]; then
    cp -f "$personal_dir"/* "$merged_dir" 2>/dev/null || true
  fi

  mkdir -p "$home_dir"
  local file
  while IFS= read -r file; do
    local base dst
    base="$(basename "$file")"
    dst="$home_dir/$base"
    copy_with_backup "$file" "$dst"
    chmod +x "$dst" 2>/dev/null || true
    info "installed function: $base"
  done < <(find "$merged_dir" -maxdepth 1 -type f | sort)

  rm -rf "$merged_dir"
}

sync_functions() {
  local mode="$1"
  local repo_rel repo_dir home_dir
  repo_rel="$(function_sync_repo_dir)"
  repo_dir="$(repo_write_path "$repo_rel")"
  home_dir="$(expand_home_path "$(function_sync_home_dir)")"

  if [[ ! -d "$home_dir" ]]; then
    warn "functions directory missing on home: $home_dir"
    OSSETUP_SYNC_FUNCTIONS_CHANGED=0
    return 0
  fi

  mkdir -p "$repo_dir"
  local changed=0
  local file
  while IFS= read -r file; do
    local base repo_file
    base="$(basename "$file")"
    repo_file="$repo_dir/$base"

    local baseline_file
    baseline_file="$repo_file"

    if [[ -f "$baseline_file" ]] && files_equal "$file" "$baseline_file"; then
      continue
    fi

    changed=$((changed + 1))
    if [[ "$mode" == "preview" ]]; then
      info "CHANGED function $base"
      continue
    fi

    cp -f "$file" "$repo_file"
    chmod +x "$repo_file" 2>/dev/null || true
    info "SYNCED function $base"
  done < <(find "$home_dir" -maxdepth 1 -type f | sort)
  OSSETUP_SYNC_FUNCTIONS_CHANGED="$changed"
}
