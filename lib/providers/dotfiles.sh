#!/usr/bin/env bash

if [[ -n "${OSSETUP_PROVIDER_DOTFILES_SH:-}" ]]; then
  return 0
fi
OSSETUP_PROVIDER_DOTFILES_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/core/manifest.sh"

apply_dotfiles() {
  local dry_run="$1"
  local entry

  while IFS= read -r entry; do
    local repo_rel home_rel mode
    repo_rel="$(jq -r '.repo' <<<"$entry")"
    home_rel="$(jq -r '.home' <<<"$entry")"
    mode="$(jq -r '.mode // empty' <<<"$entry")"

    local src dst
    src="$OSSETUP_ROOT/$repo_rel"
    dst="$(expand_home_path "$home_rel")"

    if [[ "$dry_run" == "1" ]]; then
      info "dry-run dotfile: $src -> $dst"
      continue
    fi

    copy_with_backup "$src" "$dst" "$mode"
    info "installed dotfile: $home_rel"
  done < <(dotfiles_entries)
}

sync_dotfiles() {
  local mode="$1"
  local changed=0
  local entry

  while IFS= read -r entry; do
    local repo_rel home_rel
    repo_rel="$(jq -r '.repo' <<<"$entry")"
    home_rel="$(jq -r '.home' <<<"$entry")"

    local repo_file home_file
    repo_file="$OSSETUP_ROOT/$repo_rel"
    home_file="$(expand_home_path "$home_rel")"

    if [[ ! -f "$home_file" ]]; then
      warn "missing on home: $home_rel"
      continue
    fi

    if files_equal "$home_file" "$repo_file"; then
      info "UNCHANGED $home_rel"
      continue
    fi

    changed=$((changed + 1))
    if [[ "$mode" == "preview" ]]; then
      info "CHANGED $home_rel -> $repo_rel"
      continue
    fi

    ensure_parent_dir "$repo_file"
    cp -f "$home_file" "$repo_file"
    info "SYNCED $home_rel -> $repo_rel"
  done < <(dotfiles_entries)
  OSSETUP_SYNC_DOTFILES_CHANGED="$changed"
}
