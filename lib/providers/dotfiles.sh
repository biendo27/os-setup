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
    local repo_rel home_rel mode entry_type optional
    repo_rel="$(jq -r '.repo' <<<"$entry")"
    home_rel="$(jq -r '.home' <<<"$entry")"
    mode="$(jq -r '.mode // empty' <<<"$entry")"
    entry_type="$(jq -r '.type // "file"' <<<"$entry")"
    optional="$(jq -r '.optional // false' <<<"$entry")"

    local src dst
    src="$OSSETUP_ROOT/$repo_rel"
    dst="$(expand_home_path "$home_rel")"

    case "$entry_type" in
      file)
        if [[ "$dry_run" == "1" ]]; then
          info "dry-run dotfile: $src -> $dst"
          continue
        fi

        if [[ ! -f "$src" ]]; then
          if [[ "$optional" == "true" ]]; then
            warn "optional dotfile missing in repo: $repo_rel"
            continue
          fi
          die "$E_DOTFILE" "source does not exist: $src"
        fi

        copy_with_backup "$src" "$dst" "$mode"
        info "installed dotfile: $home_rel"
        ;;
      dir)
        if [[ "$dry_run" == "1" ]]; then
          info "dry-run dotdir: $src -> $dst"
          continue
        fi

        if [[ ! -d "$src" ]]; then
          if [[ "$optional" == "true" ]]; then
            warn "optional dotdir missing in repo: $repo_rel"
            continue
          fi
          die "$E_DOTFILE" "source directory does not exist: $src"
        fi

        ensure_parent_dir "$dst"
        if [[ -e "$dst" ]]; then
          cp -a -- "$dst" "${dst}.bak.$(now_ts)"
          rm -rf -- "$dst"
        fi
        cp -a -- "$src" "$dst"
        info "installed dotdir: $home_rel"
        ;;
      *)
        die "$E_USAGE" "unknown dotfiles entry type: $entry_type ($repo_rel)"
        ;;
    esac
  done < <(dotfiles_entries)
}

sync_dotfiles() {
  local mode="$1"
  local changed=0
  local entry

  while IFS= read -r entry; do
    local repo_rel home_rel entry_type optional
    repo_rel="$(jq -r '.repo' <<<"$entry")"
    home_rel="$(jq -r '.home' <<<"$entry")"
    entry_type="$(jq -r '.type // "file"' <<<"$entry")"
    optional="$(jq -r '.optional // false' <<<"$entry")"

    local repo_file home_file
    repo_file="$OSSETUP_ROOT/$repo_rel"
    home_file="$(expand_home_path "$home_rel")"

    case "$entry_type" in
      file)
        if [[ ! -f "$home_file" ]]; then
          if [[ "$optional" == "true" ]]; then
            info "OPTIONAL missing on home: $home_rel"
          else
            warn "missing on home: $home_rel"
          fi
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
        ;;
      dir)
        if [[ ! -d "$home_file" ]]; then
          if [[ "$optional" == "true" ]]; then
            info "OPTIONAL missing on home: $home_rel"
          else
            warn "missing directory on home: $home_rel"
          fi
          continue
        fi

        if [[ -d "$repo_file" ]] && diff -qr "$home_file" "$repo_file" >/dev/null 2>&1; then
          info "UNCHANGED $home_rel"
          continue
        fi

        changed=$((changed + 1))
        if [[ "$mode" == "preview" ]]; then
          info "CHANGED $home_rel -> $repo_rel"
          continue
        fi

        ensure_parent_dir "$repo_file"
        rm -rf -- "$repo_file"
        cp -a -- "$home_file" "$repo_file"
        info "SYNCED $home_rel -> $repo_rel"
        ;;
      *)
        die "$E_USAGE" "unknown dotfiles entry type: $entry_type ($repo_rel)"
        ;;
    esac
  done < <(dotfiles_entries)
  OSSETUP_SYNC_DOTFILES_CHANGED="$changed"
}
