#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true
  chmod +x "$work/bin/setup.sh" 2>/dev/null || true
  chmod +x "$work/bin/sync-from-home.sh" 2>/dev/null || true
  chmod +x "$work/bin/setup-zsh-functions.sh" 2>/dev/null || true

  export OSSETUP_HOME_DIR="$BATS_TEST_TMPDIR/home"
  mkdir -p "$OSSETUP_HOME_DIR/.config"
  cp "$work/dotfiles/.zshrc" "$OSSETUP_HOME_DIR/.zshrc"
}

@test "setup shim warns and delegates to install command" {
  run "$work/bin/setup.sh" --dry-run --target linux-debian --profile default
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DEPRECATED] bin/setup.sh"* ]]
  [[ "$output" == *"install complete"* ]]
}

@test "sync-from-home shim warns and delegates to sync apply" {
  printf '\n# shim-sync\n' >> "$OSSETUP_HOME_DIR/.zshrc"

  run "$work/bin/sync-from-home.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DEPRECATED] bin/sync-from-home.sh"* ]]
  [[ "$output" == *"APPLY complete"* ]]
  grep -q "# shim-sync" "$work/dotfiles/.zshrc"
}

@test "setup-zsh-functions warns and keeps compatibility behavior" {
  local legacy_home="$BATS_TEST_TMPDIR/legacy-home"
  local legacy_config="$legacy_home/.config"
  mkdir -p "$legacy_config"

  run env HOME="$legacy_home" XDG_CONFIG_HOME="$legacy_config" "$work/bin/setup-zsh-functions.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DEPRECATED] bin/setup-zsh-functions.sh"* ]]
  [ -d "$legacy_config/zsh/functions" ]
  [ -f "$legacy_config/zsh/functions/update-all" ]
}
