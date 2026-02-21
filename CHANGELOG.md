# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Personal workspace contract support via `.ossetup-workspace.json` (`mode=personal-overrides`).
- Personal workspace test suite:
  - `tests/personal-workspace.bats`
- Layer resolver coverage for personal user/host overlays:
  - `tests/layers-resolver.bats` (new overlay case).

### Changed

- `install` now resolves effective dotfiles/functions with personal override fallback to core when personal workspace mode is enabled.
- `sync --apply` now writes only to personal repo in personal workspace mode and rejects apply when run from core repo.
- `sync-all --scope state --apply` now writes state snapshots to personal repo and updates personal user layer manifest in personal workspace mode.
- `verify --strict` now compares resolved manifest against state snapshots from the active write repo (personal repo in personal workspace mode).
- `promote` is now preview-only in personal workspace mode (`--apply` blocked).
- Architecture, invariants, data contracts, and README docs were updated for `core + personal` operation.

## [1.0.0] - 2026-02-20

### Changed

- Runtime is now layered-only; target resolution requires:
  - `manifests/layers/core.yaml`
  - `manifests/layers/targets/<target>.yaml`
- `install`, `doctor`, `sync-all`, `promote`, and `verify --strict` now operate only on layered manifests.
- CI and local verification commands now validate layered manifests only.
- Canonical docs were updated to remove compatibility-window guidance.

### Removed

- Layered migration compatibility adapter and all runtime fallback reads from `manifests/targets/*.yaml`.
- Legacy desired-state files:
  - `manifests/targets/linux-debian.yaml`
  - `manifests/targets/macos.yaml`
- Transitional docs:
  - `docs/deprecations.md`
  - `docs/migration-notes.md`
- Compatibility-specific test suite:
  - `tests/layers-adapter-compat.bats`

## [0.3.0] - 2026-02-20

### Added

- Git workflow governance files:
  - `.github/CODEOWNERS`
  - `.github/pull_request_template.md`
  - `.github/workflows/pr-title.yml`
- Workflow governance tests:
  - `tests/workflow-governance.bats`
- Layered manifest foundation:
  - `manifests/layers/core.yaml`
  - `manifests/layers/targets/linux-debian.yaml`
  - `manifests/layers/targets/macos.yaml`
  - `manifests/layers/hosts/.gitkeep`
  - `lib/core/layers.sh`
- Command contract expansion:
  - `install --host <id|auto>`
  - `sync-all --scope config|state|all`
  - `promote --target ... --scope ... --from-state ... --preview|--apply`
  - `verify --strict`
- New contract test suites:
  - `tests/layers-resolver.bats`
  - `tests/layers-adapter-compat.bats`
  - `tests/install-host.bats`
  - `tests/sync-all-scope.bats`
  - `tests/promote.bats`
  - `tests/verify-strict.bats`
- Release integrity tooling:
  - `bin/release-checksums.sh`
  - `bin/release-verify.sh`
- Release integrity test suites:
  - `tests/release-checksums.bats`
  - `tests/release-verify.bats`

### Changed

- CI trigger now runs on `pull_request` and `push` to `main` only.
- CI test harness is now cross-platform for Linux/macOS (`zsh` dependency + portable test fixtures).
- `CONTRIBUTING.md` now defines trunk-based/PR-only/merge-commit workflow policy.
- `docs/runbooks/RELEASE.md` now enforces release from `main` after PR checks pass.
- `README.md` now links to workflow policy location.
- `tests/docs-consistency.bats` now validates workflow governance artifacts.
- Manifest resolution now uses deterministic layered precedence (`core -> target -> host`) with legacy fallback adapter.
- State export now writes to effective target manifest path (layered target when available).
- CI manifest validation now covers layered manifests.
- CI dependencies now include `gnupg` for release integrity test coverage.
- Architecture/data-contract/invariant/runbook docs updated for layering-first rollout.
- Release runbook, README, and contributing policy now require publishing `SHA256SUMS` and `SHA256SUMS.asc`.

### Deprecated

- `manifests/targets/*.yaml` is now a compatibility path and planned for removal earliest in `v0.5.0`.

## [0.2.0] - 2026-02-19

### Added

- Canonical architecture docs:
  - `docs/architecture/ARCHITECTURE.md`
  - `docs/architecture/INVARIANTS.md`
  - `docs/architecture/DATA-CONTRACTS.md`
- Agent handoff and governance docs:
  - `docs/agents/AGENT_CONTEXT.md`
  - `docs/deprecations.md`
  - `docs/migration-notes.md`
  - `docs/cleanup/cleanup-inventory.md`
- Operational runbooks and ADR baseline:
  - `docs/runbooks/DEBUGGING.md`
  - `docs/runbooks/RELEASE.md`
  - `docs/adr/ADR-0001-manifest-layering-roadmap.md`
  - `docs/adr/ADR-0002-command-contract-expansion-roadmap.md`
- CI workflow for Linux/macOS validation:
  - `.github/workflows/ci.yml`
- MIT license file:
  - `LICENSE`
- New test coverage:
  - `tests/dead-references.bats`
  - `tests/deprecated-removal.bats`
  - `tests/docs-consistency.bats`
  - `tests/changelog-format.bats`

### Changed

- `README.md` now links canonical architecture/governance docs and license.
- `CONTRIBUTING.md` now defines changelog and release update policy.
- Bats negative assertions were hardened in:
  - `tests/update-all.bats`
  - `tests/update-globals.bats`
- Cleanup, migration, and deprecation docs now track completed shim removals.

### Removed

- Unused helper `json_read()` from `lib/core/common.sh`.
- Redundant `backup` keys from `manifests/dotfiles.yaml`.
- Deprecated shim scripts:
  - `bin/setup.sh`
  - `bin/sync-from-home.sh`
  - `bin/setup-zsh-functions.sh`

## [0.1.0] - 2026-02-19

### Added

- Initial tagged release of OSSetup v2 command surface:
  - `install`, `sync`, `sync-all`, `update-globals`, `verify`, `doctor`, `bootstrap`.

### Changed

- Added safety confirmations and option handling for `update-globals`.

[Unreleased]: https://github.com/biendo27/os-setup/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/biendo27/os-setup/compare/v0.3.0...v1.0.0
[0.3.0]: https://github.com/biendo27/os-setup/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/biendo27/os-setup/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/biendo27/os-setup/tree/v0.1.0
