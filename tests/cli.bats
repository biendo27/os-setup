#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/helpers/workspace-fixture.bash"

@test "ossetup prints help" {
  run "$BATS_TEST_DIRNAME/../bin/ossetup" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: ossetup"* ]]
  [[ "$output" == *"install"* ]]
  [[ "$output" == *"sync"* ]]
  [[ "$output" == *"sync-all"* ]]
  [[ "$output" == *"promote"* ]]
  [[ "$output" == *"update-globals"* ]]
  [[ "$output" == *"verify"* ]]
  [[ "$output" == *"--host"* ]]
  [[ "$output" == *"--scope"* ]]
  [[ "$output" == *"--strict"* ]]
}

@test "ossetup rejects unknown command" {
  run "$BATS_TEST_DIRNAME/../bin/ossetup" unknown-command
  [ "$status" -eq 64 ]
  [[ "$output" == *"Unknown command"* ]]
}

@test "install dry-run works" {
  local work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true
  setup_workspace_in_repo "$work"

  run "$work/bin/ossetup" install --dry-run --target auto --profile default
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run"* ]]
  [[ "$output" == *"install complete"* ]]
}
