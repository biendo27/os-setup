#!/usr/bin/env bash
set -euo pipefail

setup_workspace_in_repo() {
  local repo_root="$1"
  local mode="${2:-personal-only}"

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
  cp -R "$source_repo/manifests" "$personal_repo/"
  cp -R "$source_repo/dotfiles" "$personal_repo/"
  cp -R "$source_repo/functions" "$personal_repo/"
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
