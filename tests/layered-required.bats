#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true
  export OSSETUP_HOME_DIR="$BATS_TEST_TMPDIR/home"
  mkdir -p "$OSSETUP_HOME_DIR/.config"
  cp "$work/dotfiles/.zshrc" "$OSSETUP_HOME_DIR/.zshrc"
}

@test "require-layered mode fails when core layer is missing" {
  rm -f "$work/manifests/layers/core.yaml"

  run env OSSETUP_REQUIRE_LAYERED=1 "$work/bin/ossetup" install --dry-run --target linux-debian --profile default
  [ "$status" -eq 65 ]
  [[ "$output" == *"layered manifests required"* ]]
}

@test "require-layered mode fails when target layer is missing" {
  rm -f "$work/manifests/layers/targets/linux-debian.yaml"

  run env OSSETUP_REQUIRE_LAYERED=1 "$work/bin/ossetup" install --dry-run --target linux-debian --profile default
  [ "$status" -eq 65 ]
  [[ "$output" == *"layered manifests required"* ]]
}

@test "require-layered mode passes when layered manifests exist" {
  run env OSSETUP_REQUIRE_LAYERED=1 "$work/bin/ossetup" install --dry-run --target linux-debian --profile default
  [ "$status" -eq 0 ]
  [[ "$output" == *"install complete"* ]]
}
