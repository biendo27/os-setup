#!/usr/bin/env bash

if [[ -n "${OSSETUP_PROVIDER_STATE_EXPORT_SH:-}" ]]; then
  return 0
fi
OSSETUP_PROVIDER_STATE_EXPORT_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/core/manifest.sh"

state_dir_for_target() {
  local target="$1"
  printf '%s\n' "$(ossetup_write_root)/manifests/state/$target"
}

path_for_log() {
  local path="$1"
  local root

  for root in "$(ossetup_write_root)" "$(ossetup_core_root)" "$OSSETUP_ROOT"; do
    if path_is_within "$path" "$root"; then
      printf '%s\n' "${path#$root/}"
      return 0
    fi
  done

  printf '%s\n' "$path"
}

state_manifest_path_for_target() {
  local target="$1"
  local mode="$2"

  if is_personal_workspace_mode; then
    local user_id
    user_id="$(workspace_user_id)"
    [[ -n "$user_id" ]] || die "$E_PRECHECK" "workspace user_id is required for personal-only mode"

    local user_manifest
    user_manifest="$(layers_user_manifest_path "$user_id")"
    if [[ "$mode" == "apply" && ! -f "$user_manifest" ]]; then
      ensure_parent_dir "$user_manifest"
      cat >"$user_manifest" <<'JSON'
{
  "packages": {},
  "npm_globals": []
}
JSON
    fi
    printf '%s\n' "$user_manifest"
    return 0
  fi

  printf '%s\n' "$(layers_target_manifest_path "$target")"
}

lines_to_json_array() {
  local input="$1"
  printf '%s\n' "$input" | jq -Rsc 'split("\n") | map(select(length > 0))'
}

capture_apt_manual() {
  command -v apt-mark >/dev/null 2>&1 || return 2
  apt-mark showmanual 2>/dev/null | sed '/^\s*$/d' | sort -u
}

capture_flatpak_apps() {
  command -v flatpak >/dev/null 2>&1 || return 2
  flatpak list --app --columns=application 2>/dev/null | sed '/^\s*$/d' | sort -u
}

capture_snap_apps() {
  command -v snap >/dev/null 2>&1 || return 2
  snap list 2>/dev/null | awk 'NR>1 && NF>0 {print $1}' | sed '/^\s*$/d' | sort -u
}

capture_brew_formula() {
  command -v brew >/dev/null 2>&1 || return 2
  brew leaves 2>/dev/null | sed '/^\s*$/d' | sort -u
}

capture_brew_casks() {
  command -v brew >/dev/null 2>&1 || return 2
  brew list --cask 2>/dev/null | sed '/^\s*$/d' | sort -u
}

capture_npm_globals() {
  command -v npm >/dev/null 2>&1 || return 2
  npm list -g --depth=0 --json 2>/dev/null \
    | jq -r '.dependencies // {} | keys[]' \
    | sed '/^\s*$/d' \
    | sort -u
}

write_state_file() {
  local mode="$1"
  local path="$2"
  local data="$3"

  if [[ "$mode" == "preview" ]]; then
    info "state PREVIEW file: $(path_for_log "$path")"
    return 0
  fi

  ensure_parent_dir "$path"
  printf '%s\n' "$data" >"$path"
  info "state APPLY file: $(path_for_log "$path")"
}

apply_manifest_json_array() {
  local manifest="$1"
  local jq_expr="$2"
  local array_json="$3"

  local tmp
  tmp="$(mktemp)"
  jq --argjson arr "$array_json" "$jq_expr" "$manifest" >"$tmp"
  mv "$tmp" "$manifest"
}

export_linux_state() {
  local mode="$1"
  local core_target_manifest target_manifest
  core_target_manifest="$(layers_target_manifest_path linux-debian)"
  require_manifest "$core_target_manifest"
  target_manifest="$(state_manifest_path_for_target linux-debian "$mode")"

  local out_dir
  out_dir="$(state_dir_for_target linux-debian)"

  local apt_lines flatpak_lines snap_lines npm_lines
  local has_apt=0 has_flatpak=0 has_snap=0 has_npm=0

  if apt_lines="$(capture_apt_manual)"; then
    has_apt=1
    write_state_file "$mode" "$out_dir/apt-manual.txt" "$apt_lines"
  else
    warn "apt-mark unavailable; skip apt state capture"
  fi

  if flatpak_lines="$(capture_flatpak_apps)"; then
    has_flatpak=1
    write_state_file "$mode" "$out_dir/flatpak-apps.txt" "$flatpak_lines"
  else
    warn "flatpak unavailable; skip flatpak state capture"
  fi

  if snap_lines="$(capture_snap_apps)"; then
    has_snap=1
    write_state_file "$mode" "$out_dir/snap-list.txt" "$snap_lines"
  else
    warn "snap unavailable; skip snap state capture"
  fi

  if npm_lines="$(capture_npm_globals)"; then
    has_npm=1
    write_state_file "$mode" "$out_dir/npm-globals.txt" "$npm_lines"
  else
    warn "npm unavailable; skip npm globals capture"
  fi

  if [[ "$mode" == "preview" ]]; then
    return 0
  fi

  if (( has_apt == 1 )); then
    apply_manifest_json_array "$target_manifest" '.packages.apt = $arr' "$(lines_to_json_array "$apt_lines")"
  fi

  if (( has_flatpak == 1 )); then
    apply_manifest_json_array "$target_manifest" '.packages.flatpak = $arr' "$(lines_to_json_array "$flatpak_lines")"
  fi

  if (( has_snap == 1 )); then
    apply_manifest_json_array "$target_manifest" '.packages.snap = $arr' "$(lines_to_json_array "$snap_lines")"
  fi

  if (( has_npm == 1 )); then
    apply_manifest_json_array "$target_manifest" '.npm_globals = $arr' "$(lines_to_json_array "$npm_lines")"
  fi

  info "state APPLY manifest: $(path_for_log "$target_manifest")"
}

export_macos_state() {
  local mode="$1"
  local core_target_manifest target_manifest
  core_target_manifest="$(layers_target_manifest_path macos)"
  require_manifest "$core_target_manifest"
  target_manifest="$(state_manifest_path_for_target macos "$mode")"

  local out_dir
  out_dir="$(state_dir_for_target macos)"

  local brew_formula brew_casks npm_lines
  local has_formula=0 has_casks=0 has_npm=0

  if brew_formula="$(capture_brew_formula)"; then
    has_formula=1
    write_state_file "$mode" "$out_dir/brew-formula.txt" "$brew_formula"
  else
    warn "brew unavailable; skip formula capture"
  fi

  if brew_casks="$(capture_brew_casks)"; then
    has_casks=1
    write_state_file "$mode" "$out_dir/brew-casks.txt" "$brew_casks"
  else
    warn "brew unavailable; skip cask capture"
  fi

  if npm_lines="$(capture_npm_globals)"; then
    has_npm=1
    write_state_file "$mode" "$out_dir/npm-globals.txt" "$npm_lines"
  else
    warn "npm unavailable; skip npm globals capture"
  fi

  if [[ "$mode" == "preview" ]]; then
    return 0
  fi

  if (( has_formula == 1 )); then
    apply_manifest_json_array "$target_manifest" '.packages.brew = $arr' "$(lines_to_json_array "$brew_formula")"
  fi

  if (( has_casks == 1 )); then
    apply_manifest_json_array "$target_manifest" '.packages.brew_cask = $arr' "$(lines_to_json_array "$brew_casks")"
  fi

  if (( has_npm == 1 )); then
    apply_manifest_json_array "$target_manifest" '.npm_globals = $arr' "$(lines_to_json_array "$npm_lines")"
  fi

  info "state APPLY manifest: $(path_for_log "$target_manifest")"
}

export_state_for_target() {
  local target="$1"
  local mode="$2"

  case "$target" in
    linux-debian)
      export_linux_state "$mode"
      ;;
    macos)
      export_macos_state "$mode"
      ;;
    *)
      die "$E_TARGET" "unsupported target for state export: $target"
      ;;
  esac
}
