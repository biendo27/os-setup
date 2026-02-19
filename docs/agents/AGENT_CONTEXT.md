# Agent Context

## Purpose

This file is the fast handoff context for agents implementing, debugging, and extending OSSetup while preserving architecture contracts.

## Read Order (Mandatory)

1. `README.md`
2. `docs/architecture/ARCHITECTURE.md`
3. `docs/architecture/INVARIANTS.md`
4. `docs/cleanup/cleanup-inventory.md`
5. `docs/deprecations.md`
6. `CONTRIBUTING.md`

## Core Entry Points

- CLI: `bin/ossetup`
- Runner modules: `lib/runners/*.sh`
- Provider modules: `lib/providers/*.sh`
- Manifest contracts: `manifests/*.yaml`, `manifests/profiles/*.yaml`, `manifests/targets/*.yaml`

## Allowed Mutation Surfaces

- Declarative configs under `manifests/`
- Runtime/provider logic under `lib/`
- CLI contracts under `bin/ossetup`
- Tests under `tests/`
- Documentation under `docs/` and root `README.md`

## Cleanup Workflow

- Use `docs/cleanup/cleanup-inventory.md` as source of truth.
- Each candidate must be tagged `remove-now`, `archive-first`, or `keep`.
- Apply removal only after dependency checks and test coverage confirmation.
- Record outcomes in `CHANGELOG.md`, `docs/deprecations.md`, and `docs/migration-notes.md`.

## Verification Commands

```bash
bats tests
for f in $(rg --files -g '*.sh' bin lib hooks popos-migration/scripts tests) bin/ossetup; do bash -n "$f"; done
for f in manifests/*.yaml manifests/profiles/*.yaml manifests/targets/*.yaml; do jq -e . "$f" >/dev/null; done
```

## Do Not Break

- Preview/apply mutation boundaries.
- Exit code semantics in `lib/core/common.sh`.
- Migration mapping for removed/deprecated entrypoints.
- Secrets policy (reference-only, no plaintext secrets in repo).
