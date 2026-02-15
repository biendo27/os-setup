#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[DEPRECATED] bin/sync-from-home.sh -> use bin/ossetup sync --apply"
exec "$REPO_ROOT/bin/ossetup" sync --apply "$@"
