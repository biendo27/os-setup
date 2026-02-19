#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true

  export OSSETUP_HOME_DIR="$BATS_TEST_TMPDIR/home"
  mkdir -p "$OSSETUP_HOME_DIR/.config"
  cp "$work/dotfiles/.zshrc" "$OSSETUP_HOME_DIR/.zshrc"
}

@test "deprecated shim scripts are removed from bin" {
  [ ! -e "$work/bin/setup.sh" ]
  [ ! -e "$work/bin/sync-from-home.sh" ]
  [ ! -e "$work/bin/setup-zsh-functions.sh" ]
}

@test "canonical install and sync commands remain available" {
  run "$work/bin/ossetup" install --dry-run --target linux-debian --profile default
  [ "$status" -eq 0 ]
  [[ "$output" == *"install complete"* ]]

  run "$work/bin/ossetup" sync --preview
  [ "$status" -eq 0 ]
  [[ "$output" == *"PREVIEW complete"* ]]
}

@test "mit license file exists at repository root" {
  [ -f "$work/LICENSE" ]
  run rg -n '^MIT License$' "$work/LICENSE"
  [ "$status" -eq 0 ]
}

@test "runtime code has no references to removed shim scripts" {
  run rg -n 'bin/(setup\\.sh|sync-from-home\\.sh|setup-zsh-functions\\.sh)' "$work/bin" "$work/lib" "$work/functions"
  [ "$status" -eq 1 ]
}
