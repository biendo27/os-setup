# Release Runbook

## Purpose

Standardize release creation and changelog handling.

## Preconditions

1. Working tree clean.
2. All checks pass:
   - `bats tests`
   - script syntax checks
   - manifest parse checks
   - `shellcheck -S error`
3. `CHANGELOG.md` updated:
   - move release content from `Unreleased` to new version section.
   - include release date.
   - update comparison links.
4. Release changes are merged into `main` via PR (no direct push).
5. Required branch protection checks are green on merge commit lineage.

## Release Steps

1. Open PR from release branch to `main` using merge-commit strategy.
2. Ensure required checks are green:
   - `validate-ubuntu-latest`
   - `validate-macos-latest`
   - `pr-title`
3. Merge PR into `main` after checks pass.
4. Create annotated tag:
   - `git tag -a vX.Y.Z -m "vX.Y.Z"`
5. Push branch and tag:
   - `git push origin main`
   - `git push origin vX.Y.Z`
6. Create GitHub release:
   - `gh release create vX.Y.Z --title "vX.Y.Z" --notes "<summary>"`
7. Verify release:
   - `gh release view vX.Y.Z`
   - confirm URL, tag, and non-draft status.

## Post-Release

1. Reset `## [Unreleased]` section for next cycle.
2. Ensure compare links are correct.
3. Optionally delete merged release branches.
