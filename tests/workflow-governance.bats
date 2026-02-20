#!/usr/bin/env bats

@test "pr-title workflow exists with required regex and stable job name" {
  local workflow="$BATS_TEST_DIRNAME/../.github/workflows/pr-title.yml"

  [ -f "$workflow" ]
  run rg -n '^name: PR Title$' "$workflow"
  [ "$status" -eq 0 ]
  run rg -n '^  pr-title:$' "$workflow"
  [ "$status" -eq 0 ]
  run rg -n '^    name: pr-title$' "$workflow"
  [ "$status" -eq 0 ]
  run rg -n 'amannn/action-semantic-pull-request@v5' "$workflow"
  [ "$status" -eq 0 ]
  run rg -n -F "PR_TITLE_REGEX: '^(build|chore|ci|docs|feat|fix|perf|refactor|revert|test)(\\([a-z0-9._/-]+\\))?!?: .+'" "$workflow"
  [ "$status" -eq 0 ]
}

@test "ci workflow triggers on pull_request and main push only" {
  local ci="$BATS_TEST_DIRNAME/../.github/workflows/ci.yml"

  run rg -n '^  pull_request:$' "$ci"
  [ "$status" -eq 0 ]
  run rg -n '^      - main$' "$ci"
  [ "$status" -eq 0 ]
  run rg -n 'manifests/layers/core.yaml' "$ci"
  [ "$status" -eq 0 ]
  run rg -n -F 'manifests/layers/targets/*.yaml' "$ci"
  [ "$status" -eq 0 ]
  run rg -n 'gnupg' "$ci"
  [ "$status" -eq 0 ]
  run rg -n 'feat/\\*\\*' "$ci"
  [ "$status" -eq 1 ]
}

@test "repository has codeowners and pull request template" {
  [ -f "$BATS_TEST_DIRNAME/../.github/CODEOWNERS" ]
  [ -f "$BATS_TEST_DIRNAME/../.github/pull_request_template.md" ]

  run rg -n '^\* @biendo27$' "$BATS_TEST_DIRNAME/../.github/CODEOWNERS"
  [ "$status" -eq 0 ]
}
