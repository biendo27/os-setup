#!/usr/bin/env bash
set -euo pipefail

seed_personal_runtime_templates() {
  local source_repo="$1"
  local target_repo="$2"
  local template_root="$source_repo/templates/personal-data"

  [[ -d "$target_repo" ]] || mkdir -p "$target_repo"

  if [[ ! -d "$target_repo/dotfiles" ]]; then
    cp -R "$template_root/dotfiles" "$target_repo/"
  fi
  if [[ ! -d "$target_repo/functions" ]]; then
    cp -R "$template_root/functions" "$target_repo/"
  fi
}

setup_workspace_in_repo() {
  local repo_root="$1"
  local mode="${2:-personal-only}"

  seed_personal_runtime_templates "$repo_root" "$repo_root"

  cat > "$repo_root/.ossetup-workspace.json" <<JSON
{
  "schema_version": 1,
  "core_repo_url": "https://github.com/biendo27/os-setup.git",
  "core_repo_ref": "main",
  "core_repo_path": ".",
  "user_id": "test-user",
  "mode": "$mode"
}
JSON

  export OSSETUP_WORKSPACE_FILE="$repo_root/.ossetup-workspace.json"
}

seed_personal_data_from_repo() {
  local source_repo="$1"
  local personal_repo="$2"

  mkdir -p "$personal_repo"
  seed_personal_runtime_templates "$source_repo" "$personal_repo"
  cp -R "$source_repo/manifests" "$personal_repo/"
  cp -R "$source_repo/hooks" "$personal_repo/"
}

setup_personal_workspace_from_core_repo() {
  local core_repo="$1"
  local personal_repo="$2"
  local mode="${3:-personal-only}"

  seed_personal_data_from_repo "$core_repo" "$personal_repo"

  cat > "$personal_repo/.ossetup-workspace.json" <<JSON
{
  "schema_version": 1,
  "core_repo_url": "https://github.com/biendo27/os-setup.git",
  "core_repo_ref": "main",
  "core_repo_path": "../core",
  "user_id": "test-user",
  "mode": "$mode"
}
JSON

  export OSSETUP_WORKSPACE_FILE="$personal_repo/.ossetup-workspace.json"
}
