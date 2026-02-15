#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[DEPRECATED] bin/setup.sh -> use bin/ossetup install"
exec "$REPO_ROOT/bin/ossetup" install "$@"
