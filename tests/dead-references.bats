#!/usr/bin/env bats

@test "common runtime has no unused json_read helper" {
  run rg -n '^json_read\(\)' "$BATS_TEST_DIRNAME/../lib/core/common.sh"
  [ "$status" -eq 1 ]
}

@test "dotfiles manifest does not include unused backup keys" {
  run rg -n '"backup"\s*:' "$BATS_TEST_DIRNAME/../manifests/dotfiles.yaml"
  [ "$status" -eq 1 ]
}
