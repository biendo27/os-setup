#!/usr/bin/env bash

if [[ -n "${OSSETUP_RUNNER_VERIFY_SH:-}" ]]; then
  return 0
fi
OSSETUP_RUNNER_VERIFY_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/core/manifest.sh"

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
    repo_file="$OSSETUP_ROOT/$repo_rel"
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

  local repo_dir home_dir
  repo_dir="$OSSETUP_ROOT/$(function_sync_repo_dir)"
  home_dir="$(expand_home_path "$(function_sync_home_dir)")"

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
  done < <(find "$repo_dir" -maxdepth 1 -type f | sort)
}

run_verify() {
  local write_report=0

  while (( $# > 0 )); do
    case "$1" in
      --report)
        write_report=1
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

  if (( failures == 0 )); then
    printf 'PASS summary failures=0\n' >>"$report"
  else
    printf 'FAIL summary failures=%s\n' "$failures" >>"$report"
  fi

  if (( write_report == 1 )); then
    printf 'report: %s\n' "$report"
  fi

  if (( failures > 0 )); then
    die "$E_VERIFY" "verification failed (failures=$failures)"
  fi

  info "verification passed"
}
