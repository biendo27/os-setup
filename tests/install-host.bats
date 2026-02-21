#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/helpers/workspace-fixture.bash"

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true
  setup_workspace_in_repo "$work"
  export OSSETUP_HOME_DIR="$BATS_TEST_TMPDIR/home"
  mkdir -p "$OSSETUP_HOME_DIR"
}

@test "install supports --host auto in dry-run" {
  run "$work/bin/ossetup" install --dry-run --target linux-debian --profile default --host auto
  [ "$status" -eq 0 ]
  [[ "$output" == *"host="* ]]
}

@test "install supports explicit host id override" {
  run "$work/bin/ossetup" install --dry-run --target linux-debian --profile default --host my-host-01
  [ "$status" -eq 0 ]
  [[ "$output" == *"host=my-host-01"* ]]
}

@test "install rejects invalid host id" {
  run "$work/bin/ossetup" install --dry-run --target linux-debian --profile default --host invalid*host
  [ "$status" -eq 64 ]
  [[ "$output" == *"invalid host id"* ]]
}
