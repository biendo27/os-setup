#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '%s\n' "$*"
}

need_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || {
    printf 'missing required command: %s\n' "$cmd" >&2
    exit 1
  }
}

need_cmd npm
need_cmd mise
need_cmd jq

mapfile -t packages < <(
  npm ls -g --depth=0 --json 2>/dev/null \
    | jq -r '.dependencies // {} | keys[]' \
    | sort -u
)

if (( ${#packages[@]} == 0 )); then
  log "No npm global packages found."
  exit 0
fi

log "Importing ${#packages[@]} npm global packages into mise npm backend"

for pkg in "${packages[@]}"; do
  log "- npm:${pkg}@latest"
  mise use -g "npm:${pkg}@latest"
done

mise reshim
log "Done."
