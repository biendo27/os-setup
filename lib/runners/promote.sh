#!/usr/bin/env bash

if [[ -n "${OSSETUP_RUNNER_PROMOTE_SH:-}" ]]; then
  return 0
fi
OSSETUP_RUNNER_PROMOTE_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/core/manifest.sh"

promote_log_path() {
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

resolve_promote_state_dir() {
  local target="$1"
  local from_state="$2"
  local base_root
  base_root="$(ossetup_write_root)"

  if [[ "$from_state" == "latest" ]]; then
    local base_dir
    base_dir="$base_root/manifests/state/$target"
    [[ -d "$base_dir" ]] || die "$E_PRECHECK" "state directory missing: $base_dir"

    if find "$base_dir" -maxdepth 1 -type f -name '*.txt' | grep -q .; then
      printf '%s\n' "$base_dir"
      return 0
    fi

    local latest_subdir
    latest_subdir="$(find "$base_dir" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)"
    [[ -n "$latest_subdir" ]] || die "$E_PRECHECK" "no state snapshot found in: $base_dir"
    printf '%s\n' "$latest_subdir"
    return 0
  fi

  local explicit_dir
  if [[ "$from_state" = /* ]]; then
    explicit_dir="$from_state"
  else
    explicit_dir="$base_root/$from_state"
  fi

  [[ -d "$explicit_dir" ]] || die "$E_PRECHECK" "state directory missing: $explicit_dir"
  printf '%s\n' "$explicit_dir"
}

state_file_to_json_array() {
  local path="$1"
  [[ -f "$path" ]] || die "$E_PRECHECK" "state file missing: $path"
  jq -Rsc 'split("\n") | map(select(length > 0))' < "$path"
}

json_set_array_field() {
  local input_json="$1"
  local jq_expr="$2"
  local array_json="$3"
  jq --argjson arr "$array_json" "$jq_expr" <<<"$input_json"
}

promote_linux_packages() {
  local state_dir="$1"
  local manifest_json="$2"

  local apt_arr flatpak_arr snap_arr
  apt_arr="$(state_file_to_json_array "$state_dir/apt-manual.txt")"
  flatpak_arr="$(state_file_to_json_array "$state_dir/flatpak-apps.txt")"
  snap_arr="$(state_file_to_json_array "$state_dir/snap-list.txt")"

  manifest_json="$(json_set_array_field "$manifest_json" '.packages.apt = $arr' "$apt_arr")"
  manifest_json="$(json_set_array_field "$manifest_json" '.packages.flatpak = $arr' "$flatpak_arr")"
  manifest_json="$(json_set_array_field "$manifest_json" '.packages.snap = $arr' "$snap_arr")"

  printf '%s\n' "$manifest_json"
}

promote_macos_packages() {
  local state_dir="$1"
  local manifest_json="$2"

  local brew_arr cask_arr
  brew_arr="$(state_file_to_json_array "$state_dir/brew-formula.txt")"
  cask_arr="$(state_file_to_json_array "$state_dir/brew-casks.txt")"

  manifest_json="$(json_set_array_field "$manifest_json" '.packages.brew = $arr' "$brew_arr")"
  manifest_json="$(json_set_array_field "$manifest_json" '.packages.brew_cask = $arr' "$cask_arr")"

  printf '%s\n' "$manifest_json"
}

promote_npm_globals() {
  local state_dir="$1"
  local manifest_json="$2"

  local npm_arr
  npm_arr="$(state_file_to_json_array "$state_dir/npm-globals.txt")"
  manifest_json="$(json_set_array_field "$manifest_json" '.npm_globals = $arr' "$npm_arr")"

  printf '%s\n' "$manifest_json"
}

run_promote() {
  local target=""
  local scope="all"
  local from_state="latest"
  local mode="preview"

  while (( $# > 0 )); do
    case "$1" in
      --target)
        target="${2:-}"
        shift 2
        ;;
      --scope)
        scope="${2:-}"
        shift 2
        ;;
      --from-state)
        from_state="${2:-}"
        shift 2
        ;;
      --preview)
        mode="preview"
        shift
        ;;
      --apply)
        mode="apply"
        shift
        ;;
      *)
        die "$E_USAGE" "unknown promote option: $1"
        ;;
    esac
  done

  [[ -n "$target" ]] || die "$E_USAGE" "--target is required for promote"

  case "$scope" in
    packages|npm_globals|all)
      ;;
    *)
      die "$E_USAGE" "invalid scope: $scope (expected: packages|npm_globals|all)"
      ;;
  esac

  local resolved_target
  resolved_target="$(detect_target "$target")"

  local target_manifest
  target_manifest="$(layers_target_manifest_path "$resolved_target")"
  require_manifest "$target_manifest"

  local state_dir
  state_dir="$(resolve_promote_state_dir "$resolved_target" "$from_state")"

  local current_json proposed_json
  current_json="$(cat "$target_manifest")"
  proposed_json="$current_json"

  if [[ "$scope" == "packages" || "$scope" == "all" ]]; then
    case "$resolved_target" in
      linux-debian)
        proposed_json="$(promote_linux_packages "$state_dir" "$proposed_json")"
        ;;
      macos)
        proposed_json="$(promote_macos_packages "$state_dir" "$proposed_json")"
        ;;
      *)
        die "$E_TARGET" "unsupported target for promote: $resolved_target"
        ;;
    esac
  fi

  if [[ "$scope" == "npm_globals" || "$scope" == "all" ]]; then
    proposed_json="$(promote_npm_globals "$state_dir" "$proposed_json")"
  fi

  if [[ "$mode" == "preview" ]]; then
    info "PROMOTE PREVIEW target=$resolved_target scope=$scope state=$(promote_log_path "$state_dir")"
    if [[ "$(jq -S . <<<"$current_json")" == "$(jq -S . <<<"$proposed_json")" ]]; then
      info "promote preview: no changes"
    fi
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  jq . <<<"$proposed_json" > "$tmp"
  mv "$tmp" "$target_manifest"

  info "PROMOTE APPLY target=$resolved_target scope=$scope state=$(promote_log_path "$state_dir")"
}
