#!/usr/bin/env bats

@test "common runtime has no unused json_read helper" {
  run rg -n '^json_read\(\)' "$BATS_TEST_DIRNAME/../lib/core/common.sh"
  [ "$status" -eq 1 ]
}

@test "dotfiles manifest does not include unused backup keys" {
  run rg -n '"backup"\s*:' "$BATS_TEST_DIRNAME/../manifests/dotfiles.yaml"
  [ "$status" -eq 1 ]
}

@test "runtime has no references to legacy manifests/targets path" {
  run rg -n 'manifests/targets/' "$BATS_TEST_DIRNAME/../lib" "$BATS_TEST_DIRNAME/../bin"
  [ "$status" -eq 1 ]
}

@test "core repo root does not contain personal runtime data directories" {
  [ ! -d "$BATS_TEST_DIRNAME/../dotfiles" ]
  [ ! -d "$BATS_TEST_DIRNAME/../functions" ]
  [ ! -d "$BATS_TEST_DIRNAME/../archive" ]
}

@test "core repo keeps personal runtime templates for tests and bootstrap guidance" {
  [ -d "$BATS_TEST_DIRNAME/../templates/personal-data/dotfiles" ]
  [ -d "$BATS_TEST_DIRNAME/../templates/personal-data/functions" ]
}
