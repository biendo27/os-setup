# Cleanup Inventory

Last updated: 2026-02-20 (Phase 4 prep)

## Scope

Controlled cleanup for redundant scripts, docs, manifest fields, and tests while preserving architecture and compatibility contracts.

## Candidates

| Item | Classification | Status | Justification | Dependency/Safety Checks | Impact |
| --- | --- | --- | --- | --- | --- |
| `lib/core/common.sh:json_read()` | `remove-now` | Completed | Unused helper; no callsites | `rg -n "\\bjson_read\\b"` only matched declaration | No user-facing impact |
| `manifests/dotfiles.yaml` `"backup"` keys | `remove-now` | Completed | Redundant metadata; backup behavior is already implemented in provider logic | `rg -n '"backup"\\s*:' manifests/dotfiles.yaml` tracked removal; provider does not consume field | No behavior change |
| `bin/setup.sh` | `remove-now` | Completed (removed) | Deprecation window completed; canonical command available | Removal verified by `tests/deprecated-removal.bats` and dead-reference scans | Minimal migration-only impact |
| `bin/sync-from-home.sh` | `remove-now` | Completed (removed) | Deprecation window completed; canonical command available | Removal verified by `tests/deprecated-removal.bats` and dead-reference scans | Minimal migration-only impact |
| `bin/setup-zsh-functions.sh` | `remove-now` | Completed (removed) | Replaced by `ossetup install` module-driven flow | Removal verified by `tests/deprecated-removal.bats` and dead-reference scans | Minimal migration-only impact |
| `manifests/targets/*.yaml` | `remove-now` | Planned (`v1.0.0`) | Hard cutover to layered-only desired-state model | Guardrails: `tests/layered-required.bats`, dead-reference checks, CI matrix | Breaking change in `v1.0.0` |
| `docs/plans/2026-02-15-ossetup-v2-design.md` | `keep` | Kept | Historical design context still useful for evolution decisions | Referenced by maintainers during architecture reviews | Documentation continuity |

## Batch Actions Applied

1. Removed unused helper `json_read()` from `lib/core/common.sh`.
2. Removed redundant `backup` keys from `manifests/dotfiles.yaml`.
3. Removed deprecated shim scripts from `bin/`.
4. Added removal contract tests (`tests/deprecated-removal.bats`).
5. Added dead-reference tests (`tests/dead-references.bats`).
6. Added docs consistency tests (`tests/docs-consistency.bats`).
7. Added architecture/agent/deprecation/migration/changelog documentation set.
8. Introduced layered manifests + adapter lifecycle tracking (`core/target/host`).

## Deferred Actions

1. Execute final removal batch in `v1.0.0` and then delete migration/deprecation docs that are no longer needed.
