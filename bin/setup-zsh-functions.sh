#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_ROOT/functions"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/functions"
RC_FILE="$HOME/.zshrc"

echo "[DEPRECATED] bin/setup-zsh-functions.sh -> use bin/ossetup install (functions are managed by manifests/dotfiles workflow)"

mkdir -p "$TARGET_DIR"

# Copy all function files (no symlinks)
if compgen -G "$SRC_DIR/*" > /dev/null; then
  cp -f "$SRC_DIR"/* "$TARGET_DIR/"
fi

# Ensure .zshrc exists
if [[ ! -f "$RC_FILE" ]]; then
  touch "$RC_FILE"
fi

MARKER_BEGIN="# >>> custom functions >>>"

if ! grep -q "$MARKER_BEGIN" "$RC_FILE"; then
  cat >> "$RC_FILE" <<'BLOCK'
# >>> custom functions >>>
ZSH_CUSTOM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
if [[ -d "$ZSH_CUSTOM_DIR/functions" ]]; then
  fpath=("$ZSH_CUSTOM_DIR/functions" $fpath)
  autoload -Uz "$ZSH_CUSTOM_DIR"/functions/*(:t)
fi
# <<< custom functions <<<
BLOCK
fi

echo "Installed custom zsh functions to: $TARGET_DIR"
