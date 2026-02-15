#!/usr/bin/env bats

@test "ossetup prints help" {
  run "$BATS_TEST_DIRNAME/../bin/ossetup" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: ossetup"* ]]
  [[ "$output" == *"install"* ]]
  [[ "$output" == *"sync"* ]]
  [[ "$output" == *"sync-all"* ]]
  [[ "$output" == *"verify"* ]]
}

@test "ossetup rejects unknown command" {
  run "$BATS_TEST_DIRNAME/../bin/ossetup" unknown-command
  [ "$status" -eq 64 ]
  [[ "$output" == *"Unknown command"* ]]
}

@test "install dry-run works" {
  run "$BATS_TEST_DIRNAME/../bin/ossetup" install --dry-run --target linux-debian --profile default
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run"* ]]
  [[ "$output" == *"install complete"* ]]
}
