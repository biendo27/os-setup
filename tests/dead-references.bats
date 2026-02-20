#!/usr/bin/env bats

@test "common runtime has no unused json_read helper" {
  run rg -n '^json_read\(\)' "$BATS_TEST_DIRNAME/../lib/core/common.sh"
  [ "$status" -eq 1 ]
}

@test "dotfiles manifest does not include unused backup keys" {
  run rg -n '"backup"\s*:' "$BATS_TEST_DIRNAME/../manifests/dotfiles.yaml"
  [ "$status" -eq 1 ]
}

@test "runtime references manifests/targets only through layers compatibility module" {
  run rg -n 'manifests/targets/' "$BATS_TEST_DIRNAME/../lib" "$BATS_TEST_DIRNAME/../bin"
  [ "$status" -eq 0 ]

  local filtered
  filtered="$(printf '%s\n' "$output" | rg -v '/lib/core/layers.sh:' || true)"
  [ -z "$filtered" ]
}
