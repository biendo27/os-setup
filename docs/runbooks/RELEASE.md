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
4. Deprecation and migration docs updated for any contract changes:
   - `docs/deprecations.md`
   - `docs/migration-notes.md`
   - `docs/cleanup/cleanup-inventory.md`
5. Release changes are merged into `main` via PR (no direct push).
6. Required branch protection checks are green on merge commit lineage.

Compatibility window policy for layered migration:

1. `v0.3.0` introduces layered manifests + adapter.
2. `v0.4.0` still keeps adapter.
3. Adapter removal is allowed earliest in `v0.5.0` after migration gates are green.

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
