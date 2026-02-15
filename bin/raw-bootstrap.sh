#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${OSSETUP_REPO_URL:-https://github.com/emanonlabs/OSSetup.git}"
REPO_REF="${OSSETUP_REPO_REF:-main}"
INSTALL_DIR="${OSSETUP_INSTALL_DIR:-$HOME/.local/share/ossetup}"
EXPECTED_COMMIT="${OSSETUP_EXPECTED_COMMIT:-}"

mkdir -p "$(dirname "$INSTALL_DIR")"

if [[ -d "$INSTALL_DIR/.git" ]]; then
  git -C "$INSTALL_DIR" fetch --depth 1 origin "$REPO_REF"
  git -C "$INSTALL_DIR" checkout -f FETCH_HEAD
else
  git clone --depth 1 --branch "$REPO_REF" "$REPO_URL" "$INSTALL_DIR"
fi

if [[ -n "$EXPECTED_COMMIT" ]]; then
  actual_commit="$(git -C "$INSTALL_DIR" rev-parse HEAD)"
  if [[ "$actual_commit" != "$EXPECTED_COMMIT" ]]; then
    echo "commit mismatch: expected=$EXPECTED_COMMIT actual=$actual_commit" >&2
    exit 1
  fi
fi

exec "$INSTALL_DIR/bin/ossetup" install --profile default --target auto
