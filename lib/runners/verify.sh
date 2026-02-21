#!/usr/bin/env bash

if [[ -n "${OSSETUP_RUNNER_VERIFY_SH:-}" ]]; then
  return 0
fi
OSSETUP_RUNNER_VERIFY_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/core/manifest.sh"

verify_log_path() {
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

verify_commands() {
  local report="$1"
  local failures_ref="$2"

  local -a base_cmds=(zsh git curl jq)
  local cmd
  for cmd in "${base_cmds[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      printf 'PASS command %s\n' "$cmd" >>"$report"
    else
      printf 'FAIL command %s\n' "$cmd" >>"$report"
      eval "$failures_ref=$(( $failures_ref + 1 ))"
    fi
  done
}

verify_dotfiles() {
  local report="$1"
  local failures_ref="$2"
  local entry

  while IFS= read -r entry; do
    local repo_rel home_rel entry_type optional
    repo_rel="$(jq -r '.repo' <<<"$entry")"
    home_rel="$(jq -r '.home' <<<"$entry")"
    entry_type="$(jq -r '.type // "file"' <<<"$entry")"
    optional="$(jq -r '.optional // false' <<<"$entry")"

    local repo_file home_file
    repo_file="$(resolve_repo_source_path "$repo_rel" "$entry_type")"
    home_file="$(expand_home_path "$home_rel")"

    case "$entry_type" in
      file)
        if [[ ! -f "$home_file" ]]; then
          if [[ "$optional" == "true" ]]; then
            printf 'PASS optional dotfile missing %s\n' "$home_rel" >>"$report"
          else
            printf 'FAIL dotfile missing %s\n' "$home_rel" >>"$report"
            eval "$failures_ref=$(( $failures_ref + 1 ))"
          fi
          continue
        fi

        if files_equal "$repo_file" "$home_file"; then
          printf 'PASS dotfile %s\n' "$home_rel" >>"$report"
        else
          printf 'FAIL dotfile mismatch %s\n' "$home_rel" >>"$report"
          eval "$failures_ref=$(( $failures_ref + 1 ))"
        fi
        ;;
      dir)
        if [[ ! -d "$home_file" ]]; then
          if [[ "$optional" == "true" ]]; then
            printf 'PASS optional dotdir missing %s\n' "$home_rel" >>"$report"
          else
            printf 'FAIL dotdir missing %s\n' "$home_rel" >>"$report"
            eval "$failures_ref=$(( $failures_ref + 1 ))"
          fi
          continue
        fi

        if [[ -d "$repo_file" ]] && diff -qr "$repo_file" "$home_file" >/dev/null 2>&1; then
          printf 'PASS dotdir %s\n' "$home_rel" >>"$report"
        else
          printf 'FAIL dotdir mismatch %s\n' "$home_rel" >>"$report"
          eval "$failures_ref=$(( $failures_ref + 1 ))"
        fi
        ;;
      *)
        printf 'FAIL dotfile invalid-type %s (%s)\n' "$home_rel" "$entry_type" >>"$report"
        eval "$failures_ref=$(( $failures_ref + 1 ))"
        ;;
    esac
  done < <(dotfiles_entries)
}

verify_functions() {
  local report="$1"
  local failures_ref="$2"

  local repo_rel home_dir core_dir personal_dir merged_dir
  repo_rel="$(function_sync_repo_dir)"
  core_dir="$(repo_path_in_core "$repo_rel")"
  personal_dir="$(repo_path_in_personal "$repo_rel")"
  home_dir="$(expand_home_path "$(function_sync_home_dir)")"

  merged_dir="$(mktemp -d)"
  if [[ -d "$core_dir" ]]; then
    cp -f "$core_dir"/* "$merged_dir" 2>/dev/null || true
  fi
  if is_personal_workspace_mode && [[ -d "$personal_dir" ]]; then
    cp -f "$personal_dir"/* "$merged_dir" 2>/dev/null || true
  fi

  local file
  while IFS= read -r file; do
    local base home_file
    base="$(basename "$file")"
    home_file="$home_dir/$base"

    if [[ ! -f "$home_file" ]]; then
      printf 'FAIL function missing %s\n' "$base" >>"$report"
      eval "$failures_ref=$(( $failures_ref + 1 ))"
      continue
    fi

    if files_equal "$file" "$home_file"; then
      printf 'PASS function %s\n' "$base" >>"$report"
    else
      printf 'FAIL function mismatch %s\n' "$base" >>"$report"
      eval "$failures_ref=$(( $failures_ref + 1 ))"
    fi
  done < <(find "$merged_dir" -maxdepth 1 -type f | sort)

  rm -rf "$merged_dir"
}

sorted_manifest_lines() {
  local json_array="$1"
  jq -r '.[]? // empty' <<<"$json_array" | sed '/^\s*$/d' | sort -u
}

sorted_state_lines() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  sed '/^\s*$/d' "$file" | sort -u
}

verify_strict_array_drift() {
  local report="$1"
  local failures_ref="$2"
  local label="$3"
  local json_array="$4"
  local state_file="$5"

  if [[ ! -f "$state_file" ]]; then
    printf 'FAIL strict missing-state %s (%s)\n' "$label" "$(verify_log_path "$state_file")" >>"$report"
    eval "$failures_ref=$(( $failures_ref + 1 ))"
    return 0
  fi

  local manifest_tmp state_tmp
  manifest_tmp="$(mktemp)"
  state_tmp="$(mktemp)"
  sorted_manifest_lines "$json_array" >"$manifest_tmp"
  sorted_state_lines "$state_file" >"$state_tmp"

  if cmp -s "$manifest_tmp" "$state_tmp"; then
    printf 'PASS strict %s\n' "$label" >>"$report"
  else
    printf 'FAIL strict drift %s\n' "$label" >>"$report"
    eval "$failures_ref=$(( $failures_ref + 1 ))"
  fi

  rm -f "$manifest_tmp" "$state_tmp"
}

verify_strict_contracts() {
  local report="$1"
  local failures_ref="$2"

  local target
  target="$(detect_target auto)"
  local manifest_json
  manifest_json="$(resolve_target_manifest_json "$target" "${OSSETUP_HOST_ID:-}")"
  local state_dir
  state_dir="$(ossetup_write_root)/manifests/state/$target"

  if [[ ! -d "$state_dir" ]]; then
    printf 'FAIL strict missing-state-dir %s\n' "$(verify_log_path "$state_dir")" >>"$report"
    eval "$failures_ref=$(( $failures_ref + 1 ))"
    return 0
  fi

  case "$target" in
    linux-debian)
      verify_strict_array_drift "$report" "$failures_ref" "packages.apt" \
        "$(jq -c '.packages.apt // []' <<<"$manifest_json")" \
        "$state_dir/apt-manual.txt"
      verify_strict_array_drift "$report" "$failures_ref" "packages.flatpak" \
        "$(jq -c '.packages.flatpak // []' <<<"$manifest_json")" \
        "$state_dir/flatpak-apps.txt"
      verify_strict_array_drift "$report" "$failures_ref" "packages.snap" \
        "$(jq -c '.packages.snap // []' <<<"$manifest_json")" \
        "$state_dir/snap-list.txt"
      ;;
    macos)
      verify_strict_array_drift "$report" "$failures_ref" "packages.brew" \
        "$(jq -c '.packages.brew // []' <<<"$manifest_json")" \
        "$state_dir/brew-formula.txt"
      verify_strict_array_drift "$report" "$failures_ref" "packages.brew_cask" \
        "$(jq -c '.packages.brew_cask // []' <<<"$manifest_json")" \
        "$state_dir/brew-casks.txt"
      ;;
    *)
      printf 'FAIL strict unsupported-target %s\n' "$target" >>"$report"
      eval "$failures_ref=$(( $failures_ref + 1 ))"
      return 0
      ;;
  esac

  verify_strict_array_drift "$report" "$failures_ref" "npm_globals" \
    "$(jq -c '.npm_globals // []' <<<"$manifest_json")" \
    "$state_dir/npm-globals.txt"
}

run_verify() {
  local write_report=0
  local strict=0

  while (( $# > 0 )); do
    case "$1" in
      --report)
        write_report=1
        shift
        ;;
      --strict)
        strict=1
        shift
        ;;
      *)
        die "$E_USAGE" "unknown verify option: $1"
        ;;
    esac
  done

  ensure_cmd jq
  local report
  report="$(prepare_report_path verify-report.txt)"

  local failures=0
  verify_commands "$report" failures
  verify_dotfiles "$report" failures
  verify_functions "$report" failures
  if (( strict == 1 )); then
    verify_strict_contracts "$report" failures
  fi

  if (( failures == 0 )); then
    printf 'PASS summary failures=0\n' >>"$report"
  else
    printf 'FAIL summary failures=%s\n' "$failures" >>"$report"
  fi

  if (( write_report == 1 )); then
    printf 'report: %s\n' "$report"
  fi

  if (( failures > 0 )); then
    if (( strict == 1 )); then
      die "$E_VERIFY" "strict verification failed (failures=$failures)"
    fi
    die "$E_VERIFY" "verification failed (failures=$failures)"
  fi

  if (( strict == 1 )); then
    info "verification passed (strict)"
  else
    info "verification passed"
  fi
}
