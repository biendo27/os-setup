# Cleanup Inventory

Last updated: 2026-02-19

## Scope

Controlled cleanup for redundant scripts, docs, manifest fields, and tests while preserving architecture and compatibility contracts.

## Candidates

| Item | Classification | Status | Justification | Dependency/Safety Checks | Impact |
| --- | --- | --- | --- | --- | --- |
| `lib/core/common.sh:json_read()` | `remove-now` | Completed | Unused helper; no callsites | `rg -n "\\bjson_read\\b"` only matched declaration | No user-facing impact |
| `manifests/dotfiles.yaml` `"backup"` keys | `remove-now` | Completed | Redundant metadata; backup behavior is already implemented in provider logic | `rg -n '"backup"\\s*:' manifests/dotfiles.yaml` tracked removal; provider does not consume field | No behavior change |
| `bin/setup.sh` | `archive-first` | Kept (deprecation window) | Public shim entrypoint still useful for compatibility | Shim contract tested in `tests/legacy-shims.bats` | Backward-compatible warning path |
| `bin/sync-from-home.sh` | `archive-first` | Kept (deprecation window) | Public shim entrypoint still useful for compatibility | Shim contract tested in `tests/legacy-shims.bats` | Backward-compatible warning path |
| `bin/setup-zsh-functions.sh` | `archive-first` | Kept (deprecation started) | Legacy utility still used in manual workflows; replaced by `ossetup install` module-driven flow | Tracked in deprecations log + migration notes | No immediate removal |
| `docs/plans/2026-02-15-ossetup-v2-design.md` | `keep` | Kept | Historical design context still useful for evolution decisions | Referenced by maintainers during architecture reviews | Documentation continuity |

## Batch Actions Applied

1. Removed unused helper `json_read()` from `lib/core/common.sh`.
2. Removed redundant `backup` keys from `manifests/dotfiles.yaml`.
3. Added shim contract tests (`tests/legacy-shims.bats`).
4. Added dead-reference tests (`tests/dead-references.bats`).
5. Added docs consistency tests (`tests/docs-consistency.bats`).
6. Added architecture/agent/deprecation/migration/changelog documentation set.

## Deferred Actions

1. Evaluate archival/removal timing for shim scripts after one release window with deprecation notices.
2. Re-review `bin/setup-zsh-functions.sh` once usage telemetry/feedback confirms no active dependency.
