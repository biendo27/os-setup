#!/usr/bin/env bash

if [[ -n "${OSSETUP_PROVIDER_SECRETS_BW_SH:-}" ]]; then
  return 0
fi
OSSETUP_PROVIDER_SECRETS_BW_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/core/manifest.sh"

verify_bitwarden_references() {
  local dry_run="$1"
  mapfile -t entries < <(secrets_entries)

  if (( ${#entries[@]} == 0 )); then
    info "no bitwarden secret references configured"
    return 0
  fi

  if [[ "$dry_run" == "1" ]]; then
    info "dry-run bitwarden secret validation (${#entries[@]} refs)"
    return 0
  fi

  command -v bw >/dev/null 2>&1 || die "$E_SECRET" "bw CLI is required but not installed"

  local status_json
  status_json="$(bw status 2>/dev/null || true)"
  if [[ -z "$status_json" ]] || [[ "$(jq -r '.status // empty' <<<"$status_json")" != "unlocked" ]]; then
    die "$E_SECRET" "bitwarden is not unlocked (run: bw unlock)"
  fi

  local entry
  for entry in "${entries[@]}"; do
    local item required
    item="$(jq -r '.item' <<<"$entry")"
    required="$(jq -r '.required // true' <<<"$entry")"

    if bw get item "$item" >/dev/null 2>&1; then
      info "bitwarden reference available: $item"
      continue
    fi

    if [[ "$required" == "true" ]]; then
      die "$E_SECRET" "required bitwarden item not found: $item"
    fi
    warn "optional bitwarden item not found: $item"
  done
}
