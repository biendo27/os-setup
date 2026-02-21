#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/helpers/workspace-fixture.bash"

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true
  setup_workspace_in_repo "$work"
  export OSSETUP_HOME_DIR="$BATS_TEST_TMPDIR/home"
  mkdir -p "$OSSETUP_HOME_DIR/.config"
  cp "$work/dotfiles/.zshrc" "$OSSETUP_HOME_DIR/.zshrc"
}

@test "install fails when core layer is missing" {
  rm -f "$work/manifests/layers/core.yaml"

  run "$work/bin/ossetup" install --dry-run --target linux-debian --profile default
  [ "$status" -eq 65 ]
  [[ "$output" == *"layered manifests required"* ]]
}

@test "install fails when target layer is missing" {
  rm -f "$work/manifests/layers/targets/linux-debian.yaml"

  run "$work/bin/ossetup" install --dry-run --target linux-debian --profile default
  [ "$status" -eq 65 ]
  [[ "$output" == *"layered manifests required"* ]]
}

@test "install passes when layered manifests exist" {
  run "$work/bin/ossetup" install --dry-run --target linux-debian --profile default
  [ "$status" -eq 0 ]
  [[ "$output" == *"install complete"* ]]
}

@test "doctor fails fast when layered target is missing" {
  local target="linux-debian"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    target="macos"
  fi
  rm -f "$work/manifests/layers/targets/$target.yaml"

  run "$work/bin/ossetup" doctor
  [ "$status" -eq 65 ]
  [[ "$output" == *"layered manifests required"* ]]
}
