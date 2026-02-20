#!/usr/bin/env bash

if [[ -n "${OSSETUP_MANIFEST_SH:-}" ]]; then
  return 0
fi
OSSETUP_MANIFEST_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/core/layers.sh"

profile_manifest_path() {
  local profile="$1"
  printf '%s\n' "$OSSETUP_ROOT/manifests/profiles/$profile.yaml"
}

dotfiles_manifest_path() {
  printf '%s\n' "$OSSETUP_ROOT/manifests/dotfiles.yaml"
}

secrets_manifest_path() {
  printf '%s\n' "$OSSETUP_ROOT/manifests/secrets.yaml"
}

require_manifest() {
  local path="$1"
  [[ -f "$path" ]] || die "$E_PRECHECK" "manifest missing: $path"
}

profile_module_enabled() {
  local profile="$1"
  local module="$2"
  local file
  file="$(profile_manifest_path "$profile")"
  require_manifest "$file"
  jq -e --arg module "$module" '.modules[$module] == true' "$file" >/dev/null 2>&1
}

target_packages() {
  local target="$1"
  local provider="$2"
  local host_id="${3:-${OSSETUP_HOST_ID:-}}"
  local manifest_json
  manifest_json="$(resolve_target_manifest_json "$target" "$host_id")"
  jq -r --arg provider "$provider" '.packages[$provider][]? // empty' <<<"$manifest_json"
}

target_npm_globals() {
  local target="$1"
  local host_id="${2:-${OSSETUP_HOST_ID:-}}"
  local manifest_json
  manifest_json="$(resolve_target_manifest_json "$target" "$host_id")"
  jq -r '.npm_globals[]? // empty' <<<"$manifest_json"
}

dotfiles_entries() {
  local file
  file="$(dotfiles_manifest_path)"
  require_manifest "$file"
  jq -c '.entries[]' "$file"
}

function_sync_repo_dir() {
  local file
  file="$(dotfiles_manifest_path)"
  require_manifest "$file"
  jq -r '.functions.repo_dir' "$file"
}

function_sync_home_dir() {
  local file
  file="$(dotfiles_manifest_path)"
  require_manifest "$file"
  jq -r '.functions.home_dir' "$file"
}

secrets_entries() {
  local file
  file="$(secrets_manifest_path)"
  require_manifest "$file"
  jq -c '.entries[]?' "$file"
}
