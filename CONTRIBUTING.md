# Contributing

## Workflow

1. Create feature branch or worktree.
2. Implement changes in small, reviewable batches.
3. Keep cleanup actions tracked in `docs/cleanup/cleanup-inventory.md`.
4. Update docs when contracts or behavior change.
5. Update `CHANGELOG.md` for every user-facing change.

## Git Workflow Policy

1. Branching model is trunk-based:
   - `main` is always release-ready.
   - work only on short-lived feature branches.
2. Direct pushes to `main` are not allowed; use pull requests only.
3. Merge strategy is merge-commit only:
   - preserve branch lineage on `main`.
4. PR checks are mandatory before merge:
   - CI (`validate-ubuntu-latest`, `validate-macos-latest`)
   - PR title check (`pr-title`)
5. PR title must follow:
   - `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|test)(\([a-z0-9._/-]+\))?!?: .+`
6. Feature branches are auto-deleted after merge.

## Required Checks

Run all checks before opening or updating PR:

```bash
bats tests
for f in $(rg --files -g '*.sh' bin lib hooks popos-migration/scripts tests) bin/ossetup; do bash -n "$f"; done
for f in manifests/*.yaml manifests/profiles/*.yaml manifests/targets/*.yaml manifests/layers/core.yaml manifests/layers/targets/*.yaml; do jq -e . "$f" >/dev/null; done
```

If available locally, also run:

```bash
shellcheck -S error $(rg -l '^#!/usr/bin/env bash' bin lib hooks popos-migration/scripts tests) bin/ossetup
```

## Changelog and Versioning

1. Changelog format follows:
   - [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
   - [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
2. `CHANGELOG.md` must contain:
   - `## [Unreleased]`
   - versioned sections in form `## [X.Y.Z] - YYYY-MM-DD`
   - comparison links at the bottom.
3. PR rule:
   - add entries under `Unreleased` for user-visible changes.
4. Release rule:
   - move `Unreleased` entries into the new version section,
   - set release date,
   - update compare links,
   - create annotated git tag `vX.Y.Z`,
   - publish release assets with:
     - `SHA256SUMS`
     - `SHA256SUMS.asc` (detached GPG signature).

## Release Integrity Policy

1. `SHA256` checksums are mandatory for every release artifact.
2. Checksum file must be signed using GPG detached ASCII signature.
3. Recommended command sequence:
   - `./bin/release-checksums.sh --assets-dir <release-dir> --sign-key <key-id>`
   - `./bin/release-verify.sh --assets-dir <release-dir>`
4. `SHA512` is optional and only required for explicit compliance contexts.

## Cleanup Rules

1. Every candidate must be listed in `docs/cleanup/cleanup-inventory.md`.
2. Classify each item as:
   - `remove-now`
   - `archive-first`
   - `keep`
3. Do not remove compatibility-sensitive items without:
   - deprecation notice,
   - migration notes,
   - test coverage.
4. Layered manifest adapter lifecycle:
   - introduced in `v0.3.0`,
   - kept through `v0.4.0`,
   - eligible for removal earliest in `v0.5.0`.

## Testing Standards

1. Add tests for new behavior and regressions.
2. Prefer contract-style tests for CLI entrypoints and shims.
3. Reject false-positive patterns in tests (e.g. direct `! grep` in bats assertions).

## Documentation Standards

1. Keep these docs in sync:
   - `README.md`
   - `docs/architecture/ARCHITECTURE.md`
   - `docs/architecture/INVARIANTS.md`
   - `docs/architecture/DATA-CONTRACTS.md`
   - `docs/agents/AGENT_CONTEXT.md`
   - `docs/runbooks/DEBUGGING.md`
   - `docs/runbooks/RELEASE.md`
   - `docs/adr/ADR-0001-manifest-layering-roadmap.md`
   - `docs/adr/ADR-0002-command-contract-expansion-roadmap.md`
   - `docs/deprecations.md`
   - `docs/migration-notes.md`
   - `CHANGELOG.md`
