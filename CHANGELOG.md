# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Nothing yet.

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

[Unreleased]: https://github.com/biendo27/os-setup/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/biendo27/os-setup/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/biendo27/os-setup/tree/v0.1.0
