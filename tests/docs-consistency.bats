#!/usr/bin/env bats

@test "canonical architecture and contributor docs exist" {
  local root="$BATS_TEST_DIRNAME/.."
  local -a docs=(
    "$root/docs/architecture/ARCHITECTURE.md"
    "$root/docs/architecture/INVARIANTS.md"
    "$root/docs/agents/AGENT_CONTEXT.md"
    "$root/docs/cleanup/cleanup-inventory.md"
    "$root/docs/deprecations.md"
    "$root/docs/migration-notes.md"
    "$root/CONTRIBUTING.md"
    "$root/CHANGELOG.md"
  )

  local path
  for path in "${docs[@]}"; do
    [ -f "$path" ]
  done
}

@test "README links to canonical docs and cleanup inventory" {
  local readme="$BATS_TEST_DIRNAME/../README.md"

  run rg -n 'docs/architecture/ARCHITECTURE.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n 'docs/architecture/INVARIANTS.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n 'docs/agents/AGENT_CONTEXT.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n 'docs/cleanup/cleanup-inventory.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n 'CONTRIBUTING.md' "$readme"
  [ "$status" -eq 0 ]
}

@test "deprecation log tracks legacy shim scripts" {
  local deprecations="$BATS_TEST_DIRNAME/../docs/deprecations.md"

  run rg -n 'bin/setup.sh' "$deprecations"
  [ "$status" -eq 0 ]
  run rg -n 'bin/sync-from-home.sh' "$deprecations"
  [ "$status" -eq 0 ]
  run rg -n 'bin/setup-zsh-functions.sh' "$deprecations"
  [ "$status" -eq 0 ]
}
