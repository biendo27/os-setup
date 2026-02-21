#!/usr/bin/env bash

if [[ -n "${OSSETUP_COMMON_SH:-}" ]]; then
  return 0
fi
OSSETUP_COMMON_SH=1

OSSETUP_ROOT="${OSSETUP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
OSSETUP_HOME="${OSSETUP_HOME_DIR:-$HOME}"

if [[ -n "${OSSETUP_REPORTS_DIR+x}" ]]; then
  OSSETUP_REPORTS_DIR_IS_DEFAULT=0
else
  OSSETUP_REPORTS_DIR="$OSSETUP_ROOT/reports"
  OSSETUP_REPORTS_DIR_IS_DEFAULT=1
fi

if [[ -n "${OSSETUP_LOCK_DIR+x}" ]]; then
  OSSETUP_LOCK_DIR_IS_DEFAULT=0
else
  OSSETUP_LOCK_DIR="$OSSETUP_ROOT/.ossetup.lock"
  OSSETUP_LOCK_DIR_IS_DEFAULT=1
fi

OSSETUP_WORKSPACE_MODE="${OSSETUP_WORKSPACE_MODE:-}"
OSSETUP_CORE_ROOT="${OSSETUP_CORE_ROOT:-$OSSETUP_ROOT}"
OSSETUP_PERSONAL_ROOT="${OSSETUP_PERSONAL_ROOT:-$OSSETUP_ROOT}"
OSSETUP_DATA_ROOT="${OSSETUP_DATA_ROOT:-$OSSETUP_ROOT}"
OSSETUP_WORKSPACE_USER_ID="${OSSETUP_WORKSPACE_USER_ID:-}"

readonly E_USAGE=64
readonly E_PRECHECK=65
readonly E_TARGET=66
readonly E_INSTALL=67
readonly E_DOTFILE=68
readonly E_SECRET=69
readonly E_VERIFY=70

now_ts() {
  date +%Y%m%d-%H%M%S
}

log() {
  printf '%s\n' "$*"
}

info() {
  log "[INFO] $*"
}

warn() {
  log "[WARN] $*" >&2
}

error() {
  log "[ERROR] $*" >&2
}

die() {
  local code="$1"
  shift
  error "$*"
  exit "$code"
}

ensure_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "$E_PRECHECK" "missing command: $cmd"
}

expand_home_path() {
  local input="$1"
  if [[ "$input" == "~" ]]; then
    printf '%s\n' "$OSSETUP_HOME"
    return
  fi
  if [[ "${input:0:2}" == "~/" ]]; then
    printf '%s/%s\n' "$OSSETUP_HOME" "${input#\~/}"
    return
  fi
  printf '%s\n' "$input"
}

ensure_parent_dir() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
}

backup_file() {
  local path="$1"
  if [[ -e "$path" ]]; then
    cp -f "$path" "${path}.bak.$(now_ts)"
  fi
}

copy_with_backup() {
  local src="$1"
  local dst="$2"
  local mode="${3:-}"

  [[ -f "$src" ]] || die "$E_DOTFILE" "source does not exist: $src"
  ensure_parent_dir "$dst"
  backup_file "$dst"
  cp -f "$src" "$dst"
  if [[ -n "$mode" ]]; then
    chmod "$mode" "$dst"
  fi
}

files_equal() {
  local a="$1"
  local b="$2"
  [[ -f "$a" && -f "$b" ]] || return 1
  cmp -s "$a" "$b"
}

acquire_lock() {
  local waited=0
  while ! mkdir "$OSSETUP_LOCK_DIR" 2>/dev/null; do
    waited=$((waited + 1))
    if (( waited > 30 )); then
      die "$E_PRECHECK" "could not acquire lock at $OSSETUP_LOCK_DIR"
    fi
    sleep 1
  done
  trap 'release_lock' EXIT INT TERM
}

release_lock() {
  rmdir "$OSSETUP_LOCK_DIR" 2>/dev/null || true
}

detect_target() {
  local requested="${1:-auto}"
  if [[ "$requested" != "auto" ]]; then
    printf '%s\n' "$requested"
    return
  fi

  case "$(uname -s)" in
    Darwin)
      printf '%s\n' "macos"
      return
      ;;
  esac

  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}" in
      ubuntu|debian|linuxmint|pop)
        printf '%s\n' "linux-debian"
        return
        ;;
    esac
  fi

  die "$E_TARGET" "unsupported target; use --target linux-debian or macos"
}

is_personal_workspace_mode() {
  [[ "${OSSETUP_WORKSPACE_MODE:-}" == "personal-only" ]]
}

set_workspace_roots() {
  local mode="$1"
  local core_root="$2"
  local personal_root="$3"
  local user_id="${4:-}"

  OSSETUP_WORKSPACE_MODE="$mode"
  OSSETUP_CORE_ROOT="$core_root"
  OSSETUP_PERSONAL_ROOT="$personal_root"
  OSSETUP_DATA_ROOT="$personal_root"
  OSSETUP_WORKSPACE_USER_ID="$user_id"

  if [[ "${OSSETUP_REPORTS_DIR_IS_DEFAULT:-1}" == "1" ]]; then
    OSSETUP_REPORTS_DIR="$OSSETUP_DATA_ROOT/reports"
  fi
  if [[ "${OSSETUP_LOCK_DIR_IS_DEFAULT:-1}" == "1" ]]; then
    OSSETUP_LOCK_DIR="$OSSETUP_DATA_ROOT/.ossetup.lock"
  fi
}

ossetup_core_root() {
  printf '%s\n' "${OSSETUP_CORE_ROOT:-$OSSETUP_ROOT}"
}

ossetup_personal_root() {
  printf '%s\n' "${OSSETUP_PERSONAL_ROOT:-$OSSETUP_ROOT}"
}

ossetup_write_root() {
  ossetup_personal_root
}

workspace_user_id() {
  printf '%s\n' "${OSSETUP_WORKSPACE_USER_ID:-}"
}

path_is_within() {
  local path="$1"
  local root="$2"
  case "$path" in
    "$root"|"$root"/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

run_hook_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0

  local hook
  while IFS= read -r hook; do
    if [[ -x "$hook" ]]; then
      info "running hook: ${hook#$OSSETUP_ROOT/}"
      "$hook"
    fi
  done < <(find "$dir" -maxdepth 1 -type f | sort)
}

prepare_report_path() {
  local name="$1"
  local ts
  ts="$(now_ts)"
  local dir="$OSSETUP_REPORTS_DIR/$ts"
  mkdir -p "$dir"
  printf '%s\n' "$dir/$name"
}
