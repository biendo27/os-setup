#!/usr/bin/env bash

if [[ -n "${OSSETUP_PROVIDER_GLOBAL_SHIM_SH:-}" ]]; then
  return 0
fi
OSSETUP_PROVIDER_GLOBAL_SHIM_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"

global_shim_path() {
  printf '%s\n' "$OSSETUP_HOME/.local/bin/ossetup"
}

global_shim_target() {
  printf '%s\n' "$OSSETUP_ROOT/bin/ossetup"
}

ensure_local_bin_in_path() {
  local dry_run="$1"
  local rc_file="$OSSETUP_HOME/.zshrc"
  local marker_begin="# >>> ossetup path >>>"
  local marker_end="# <<< ossetup path <<<"
  local path_line='export PATH="$HOME/.local/bin:$PATH"'

  if [[ "$PATH" == *"$OSSETUP_HOME/.local/bin"* ]]; then
    info "path already contains $OSSETUP_HOME/.local/bin"
  else
    warn "$OSSETUP_HOME/.local/bin is not in current PATH"
  fi

  if [[ "$dry_run" == "1" ]]; then
    info "dry-run ensure PATH block in $rc_file"
    return 0
  fi

  if [[ ! -f "$rc_file" ]]; then
    ensure_parent_dir "$rc_file"
    touch "$rc_file"
  fi

  if grep -Fq "$marker_begin" "$rc_file"; then
    info "zshrc already contains ossetup PATH block"
    return 0
  fi

  cat >>"$rc_file" <<EOF
$marker_begin
$path_line
$marker_end
EOF
  info "added ossetup PATH block to $rc_file"
}

install_global_shim() {
  local dry_run="$1"
  local shim target
  shim="$(global_shim_path)"
  target="$(global_shim_target)"

  if [[ "$dry_run" == "1" ]]; then
    info "dry-run global shim: $shim -> $target"
    ensure_local_bin_in_path "1"
    return 0
  fi

  ensure_parent_dir "$shim"

  cat >"$shim" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "$target" "\$@"
EOF
  chmod +x "$shim"
  info "installed global shim: $shim"

  ensure_local_bin_in_path "0"
}

check_global_shim() {
  local require_global="$1"
  local shim target
  shim="$(global_shim_path)"
  target="$(global_shim_target)"

  if [[ ! -x "$shim" ]]; then
    if [[ "$require_global" == "1" ]]; then
      die "$E_PRECHECK" "global ossetup shim missing: $shim"
    fi
    warn "global ossetup shim missing: $shim"
    return 0
  fi

  if ! grep -Fq "exec \"$target\" \"\$@\"" "$shim"; then
    if [[ "$require_global" == "1" ]]; then
      die "$E_PRECHECK" "global ossetup shim has unexpected target: $shim"
    fi
    warn "global ossetup shim target mismatch: $shim"
    return 0
  fi

  local resolved=""
  resolved="$(command -v ossetup || true)"
  if [[ -z "$resolved" ]]; then
    if [[ "$require_global" == "1" ]]; then
      die "$E_PRECHECK" "ossetup not found in PATH (expected $shim)"
    fi
    warn "ossetup not found in PATH (expected $shim)"
    return 0
  fi

  if [[ "$resolved" != "$shim" ]]; then
    if [[ "$require_global" == "1" ]]; then
      die "$E_PRECHECK" "ossetup resolves to unexpected path: $resolved (expected $shim)"
    fi
    warn "ossetup resolves to unexpected path: $resolved (expected $shim)"
    return 0
  fi

  info "global shim ok: $shim"
}
