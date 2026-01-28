#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES_DIR="$REPO_ROOT/dotfiles"
FUNCTIONS_DIR="$REPO_ROOT/functions"

log() {
  printf "%s\n" "$*"
}

copy_if_exists() {
  local src="$1"
  local dst="$2"

  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -f "$src" "$dst"
    log "synced: $src -> $dst"
  fi
}

log "==> Syncing dotfiles from HOME into repo"

copy_if_exists "$HOME/.zshrc" "$DOTFILES_DIR/.zshrc"
copy_if_exists "$HOME/.zimrc" "$DOTFILES_DIR/.zimrc"
copy_if_exists "$HOME/.config/starship.toml" "$DOTFILES_DIR/.config/starship.toml"
copy_if_exists "$HOME/.config/mise/config.toml" "$DOTFILES_DIR/.config/mise/config.toml"
copy_if_exists "$HOME/.ssh/config" "$DOTFILES_DIR/.ssh/config"
copy_if_exists "$HOME/.config/Code/User/settings.json" \
  "$DOTFILES_DIR/.config/Code/User/settings.json"
copy_if_exists "$HOME/.config/Code/User/keybindings.json" \
  "$DOTFILES_DIR/.config/Code/User/keybindings.json"

log "==> Syncing zsh functions"
if [[ -d "$HOME/.config/zsh/functions" ]]; then
  mkdir -p "$FUNCTIONS_DIR"
  cp -f "$HOME/.config/zsh/functions"/* "$FUNCTIONS_DIR/" 2>/dev/null || true
fi

log "==> Done"
