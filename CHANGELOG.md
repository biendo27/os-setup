# Changelog

## Unreleased

### Added

- Canonical architecture docs:
  - `docs/architecture/ARCHITECTURE.md`
  - `docs/architecture/INVARIANTS.md`
- Agent handoff document:
  - `docs/agents/AGENT_CONTEXT.md`
- Controlled cleanup tracking:
  - `docs/cleanup/cleanup-inventory.md`
  - `docs/deprecations.md`
  - `docs/migration-notes.md`
- New test coverage:
  - `tests/dead-references.bats`
  - `tests/legacy-shims.bats`
  - `tests/docs-consistency.bats`

### Changed

- README now links canonical docs and cleanup/deprecation artifacts.
- Bats negative assertions now use `run ! ...` in:
  - `tests/update-all.bats`
  - `tests/update-globals.bats`

### Removed

- Unused helper `json_read()` from `lib/core/common.sh`.
- Redundant `backup` keys from `manifests/dotfiles.yaml`.

### Deprecated

- `bin/setup-zsh-functions.sh` is now tracked as deprecated utility in compatibility window.
