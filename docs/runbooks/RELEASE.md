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
4. Release-impact docs updated for any contract changes:
   - `docs/cleanup/cleanup-inventory.md`
   - architecture docs (`docs/architecture/*`)
   - `README.md`
5. Release changes are merged into `main` via PR (no direct push).
6. Required branch protection checks are green on merge commit lineage.
7. Release integrity tooling prerequisites are available:
   - `gpg`
   - `sha256sum` (Linux) or `shasum` (macOS fallback)

Runtime contract policy:

1. `v1.0.0` is layered-only.
2. Runtime must not read from `manifests/targets/*.yaml`.

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
6. Build release artifacts into a single directory (example: `dist/release/`).
7. Generate release checksums and detached signature:
   - `./bin/release-checksums.sh --assets-dir dist/release --sign-key <key-id>`
   - outputs:
     - `dist/release/SHA256SUMS`
     - `dist/release/SHA256SUMS.asc`
8. Export release public key:
   - `gpg --armor --export <key-id> > dist/release/RELEASE-PUBLIC-KEY.asc`
9. Verify local integrity before upload:
   - `./bin/release-verify.sh --assets-dir dist/release`
10. Create GitHub release and upload artifacts + checksum assets:
   - `gh release create vX.Y.Z dist/release/* --title "vX.Y.Z" --notes "<summary>"`
11. Verify release:
   - `gh release view vX.Y.Z`
   - confirm URL, tag, non-draft status, and presence of:
     - release artifacts
     - `SHA256SUMS`
     - `SHA256SUMS.asc`
     - `RELEASE-PUBLIC-KEY.asc`

## Post-Release

1. Reset `## [Unreleased]` section for next cycle.
2. Ensure compare links are correct.
3. Optionally delete merged release branches.

## Integrity Policy

1. `SHA256` is mandatory for every release artifact via `SHA256SUMS`.
2. `SHA256SUMS` must be signed with GPG detached ASCII signature (`SHA256SUMS.asc`).
3. Additional hash algorithms (e.g. `SHA512`) are optional and only required when explicit compliance demands it.
