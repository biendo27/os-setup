#!/usr/bin/env bats

@test "canonical architecture and contributor docs exist" {
  local root="$BATS_TEST_DIRNAME/.."
  local -a docs=(
    "$root/docs/architecture/ARCHITECTURE.md"
    "$root/docs/architecture/INVARIANTS.md"
    "$root/docs/architecture/DATA-CONTRACTS.md"
    "$root/docs/agents/AGENT_CONTEXT.md"
    "$root/docs/runbooks/DEBUGGING.md"
    "$root/docs/runbooks/RELEASE.md"
    "$root/docs/adr/ADR-0001-manifest-layering-roadmap.md"
    "$root/docs/adr/ADR-0002-command-contract-expansion-roadmap.md"
    "$root/docs/plans/2026-02-19-phase3-4-execution-roadmap.md"
    "$root/docs/cleanup/cleanup-inventory.md"
    "$root/docs/deprecations.md"
    "$root/docs/migration-notes.md"
    "$root/.github/CODEOWNERS"
    "$root/.github/pull_request_template.md"
    "$root/.github/workflows/pr-title.yml"
    "$root/CONTRIBUTING.md"
    "$root/CHANGELOG.md"
    "$root/LICENSE"
  )

  local path
  for path in "${docs[@]}"; do
    [ -f "$path" ]
  done
}

@test "README links to canonical docs, cleanup inventory, and license" {
  local readme="$BATS_TEST_DIRNAME/../README.md"

  run rg -n 'docs/architecture/ARCHITECTURE.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n 'docs/architecture/INVARIANTS.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n 'docs/architecture/DATA-CONTRACTS.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n 'docs/agents/AGENT_CONTEXT.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n 'docs/runbooks/DEBUGGING.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n 'docs/runbooks/RELEASE.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n 'docs/adr/ADR-0001-manifest-layering-roadmap.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n 'docs/adr/ADR-0002-command-contract-expansion-roadmap.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n 'docs/plans/2026-02-19-phase3-4-execution-roadmap.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n 'docs/cleanup/cleanup-inventory.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n 'CONTRIBUTING.md' "$readme"
  [ "$status" -eq 0 ]
  run rg -n '\(LICENSE\)' "$readme"
  [ "$status" -eq 0 ]
}

@test "deprecation log tracks removed legacy shim scripts" {
  local deprecations="$BATS_TEST_DIRNAME/../docs/deprecations.md"

  run rg -n 'Completed Removals' "$deprecations"
  [ "$status" -eq 0 ]
  run rg -n 'bin/setup.sh' "$deprecations"
  [ "$status" -eq 0 ]
  run rg -n 'bin/sync-from-home.sh' "$deprecations"
  [ "$status" -eq 0 ]
  run rg -n 'bin/setup-zsh-functions.sh' "$deprecations"
  [ "$status" -eq 0 ]
}

@test "contributing guide defines changelog policy" {
  local contributing="$BATS_TEST_DIRNAME/../CONTRIBUTING.md"

  run rg -n 'Keep a Changelog' "$contributing"
  [ "$status" -eq 0 ]
  run rg -n 'Semantic Versioning' "$contributing"
  [ "$status" -eq 0 ]
  run rg -n '\[Unreleased\]' "$contributing"
  [ "$status" -eq 0 ]
}

@test "contributing guide defines trunk-based workflow policy" {
  local contributing="$BATS_TEST_DIRNAME/../CONTRIBUTING.md"

  run rg -n 'trunk-based' "$contributing"
  [ "$status" -eq 0 ]
  run rg -n 'Direct pushes to `main` are not allowed' "$contributing"
  [ "$status" -eq 0 ]
  run rg -n 'merge-commit only' "$contributing"
  [ "$status" -eq 0 ]
}

@test "layered manifest baseline files exist" {
  local root="$BATS_TEST_DIRNAME/.."

  [ -f "$root/manifests/layers/core.yaml" ]
  [ -f "$root/manifests/layers/targets/linux-debian.yaml" ]
  [ -f "$root/manifests/layers/targets/macos.yaml" ]
  [ -f "$root/manifests/layers/hosts/.gitkeep" ]
}
