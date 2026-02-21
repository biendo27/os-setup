#!/usr/bin/env bash
set -euo pipefail

CORE_REPO_URL="${OSSETUP_CORE_REPO_URL:-${OSSETUP_REPO_URL:-https://github.com/biendo27/os-setup.git}}"
CORE_REPO_REF="${OSSETUP_CORE_REPO_REF:-${OSSETUP_REPO_REF:-main}}"
CORE_DIR="${OSSETUP_CORE_DIR:-${OSSETUP_INSTALL_DIR:-$HOME/.local/share/OSSetup}}"
CORE_EXPECTED_COMMIT="${OSSETUP_EXPECTED_COMMIT:-}"

PERSONAL_REPO_URL="${OSSETUP_PERSONAL_REPO_URL:-}"
PERSONAL_REPO_REF="${OSSETUP_PERSONAL_REPO_REF:-main}"
PERSONAL_DIR="${OSSETUP_PERSONAL_DIR:-$HOME/.local/share/ossetup-personal}"
PERSONAL_EXPECTED_COMMIT="${OSSETUP_PERSONAL_EXPECTED_COMMIT:-}"

PROFILE="${OSSETUP_PROFILE:-default}"
TARGET="${OSSETUP_TARGET:-auto}"
HOST="${OSSETUP_HOST:-auto}"

ensure_repo_checkout() {
  local url="$1"
  local ref="$2"
  local dst="$3"

  mkdir -p "$(dirname "$dst")"
  if [[ -d "$dst/.git" ]]; then
    git -C "$dst" fetch --depth 1 origin "$ref"
    git -C "$dst" checkout -f FETCH_HEAD
  else
    git clone --depth 1 --branch "$ref" "$url" "$dst"
  fi
}

verify_commit_if_requested() {
  local expected="$1"
  local dst="$2"
  local label="$3"

  if [[ -n "$expected" ]]; then
    local actual
    actual="$(git -C "$dst" rev-parse HEAD)"
    if [[ "$actual" != "$expected" ]]; then
      echo "$label commit mismatch: expected=$expected actual=$actual" >&2
      exit 1
    fi
  fi
}

seed_if_missing() {
  local src="$1"
  local dst="$2"
  if [[ -e "$dst" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp -R "$src" "$dst"
}

resolve_user_id() {
  local raw
  raw="${OSSETUP_USER_ID:-$(id -un 2>/dev/null || true)}"
  raw="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//')"
  if [[ -z "$raw" ]]; then
    raw="user"
  fi
  printf '%s\n' "$raw"
}

write_workspace_if_missing() {
  local personal_root="$1"
  local core_root="$2"
  local user_id="$3"
  local ws_file="$personal_root/.ossetup-workspace.json"

  if [[ -f "$ws_file" ]]; then
    return 0
  fi

  cat > "$ws_file" <<JSON
{
  "schema_version": 1,
  "core_repo_url": "$CORE_REPO_URL",
  "core_repo_ref": "$CORE_REPO_REF",
  "core_repo_path": "$core_root",
  "user_id": "$user_id",
  "mode": "personal-only"
}
JSON
}

seed_personal_workspace() {
  local core_root="$1"
  local personal_root="$2"
  local user_id
  user_id="$(resolve_user_id)"

  mkdir -p "$personal_root"
  seed_if_missing "$core_root/manifests" "$personal_root/manifests"
  seed_if_missing "$core_root/hooks" "$personal_root/hooks"
  seed_if_missing "$core_root/templates/personal-data/dotfiles" "$personal_root/dotfiles"
  seed_if_missing "$core_root/templates/personal-data/functions" "$personal_root/functions"
  mkdir -p "$personal_root/manifests/layers/users" "$personal_root/manifests/layers/hosts"
  write_workspace_if_missing "$personal_root" "$core_root" "$user_id"
}

delegate_to_personal_bootstrap() {
  local script="$PERSONAL_DIR/bin/raw-bootstrap.sh"
  if [[ ! -f "$script" ]]; then
    echo "[ERROR] personal bootstrap script missing: $script" >&2
    exit 65
  fi
  exec bash "$script"
}

run_install_from_core() {
  local ws_file="$PERSONAL_DIR/.ossetup-workspace.json"
  export OSSETUP_WORKSPACE_FILE="$ws_file"
  if [[ "${OSSETUP_BOOTSTRAP_SKIP_INSTALL:-0}" == "1" ]]; then
    echo "bootstrap initialized (install skipped)"
    return 0
  fi
  cd "$PERSONAL_DIR"
  exec "$CORE_DIR/bin/ossetup" install --profile "$PROFILE" --target "$TARGET" --host "$HOST"
}

main() {
  if [[ -n "$PERSONAL_REPO_URL" ]]; then
    ensure_repo_checkout "$PERSONAL_REPO_URL" "$PERSONAL_REPO_REF" "$PERSONAL_DIR"
    verify_commit_if_requested "$PERSONAL_EXPECTED_COMMIT" "$PERSONAL_DIR" "personal"
    delegate_to_personal_bootstrap
  fi

  ensure_repo_checkout "$CORE_REPO_URL" "$CORE_REPO_REF" "$CORE_DIR"
  verify_commit_if_requested "$CORE_EXPECTED_COMMIT" "$CORE_DIR" "core"
  seed_personal_workspace "$CORE_DIR" "$PERSONAL_DIR"
  run_install_from_core
}

main "$@"
