#!/usr/bin/env bats

@test "changelog follows keep-a-changelog and semver headings" {
  local changelog="$BATS_TEST_DIRNAME/../CHANGELOG.md"

  run rg -n '^# Changelog$' "$changelog"
  [ "$status" -eq 0 ]
  run rg -n 'Keep a Changelog' "$changelog"
  [ "$status" -eq 0 ]
  run rg -n 'Semantic Versioning' "$changelog"
  [ "$status" -eq 0 ]

  run rg -n '^## \[Unreleased\]$' "$changelog"
  [ "$status" -eq 0 ]
  run rg -n '^## \[0\.2\.0\] - 2026-02-19$' "$changelog"
  [ "$status" -eq 0 ]
  run rg -n '^## \[0\.1\.0\] - 2026-02-19$' "$changelog"
  [ "$status" -eq 0 ]
}

@test "current release section contains user-facing grouped entries" {
  local changelog="$BATS_TEST_DIRNAME/../CHANGELOG.md"

  run rg -n '^## \[0\.2\.0\] - 2026-02-19$' "$changelog"
  [ "$status" -eq 0 ]
  run rg -n '^### Added$' "$changelog"
  [ "$status" -eq 0 ]
  run rg -n '^### Changed$' "$changelog"
  [ "$status" -eq 0 ]
  run rg -n '^### Removed$' "$changelog"
  [ "$status" -eq 0 ]
}

@test "changelog compare links are present and ordered" {
  local changelog="$BATS_TEST_DIRNAME/../CHANGELOG.md"

  run rg -n '^\[Unreleased\]: https://github\.com/biendo27/os-setup/compare/v0\.2\.0\.\.\.HEAD$' "$changelog"
  [ "$status" -eq 0 ]
  run rg -n '^\[0\.2\.0\]: https://github\.com/biendo27/os-setup/compare/v0\.1\.0\.\.\.v0\.2\.0$' "$changelog"
  [ "$status" -eq 0 ]
  run rg -n '^\[0\.1\.0\]: https://github\.com/biendo27/os-setup/releases/tag/v0\.1\.0$' "$changelog"
  [ "$status" -eq 0 ]
}
