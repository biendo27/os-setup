# Agent Context

## Purpose

Fast handoff context for agents implementing, debugging, and extending OSSetup while preserving architecture contracts.

## Read Order (Mandatory)

1. `README.md`
2. `docs/architecture/ARCHITECTURE.md`
3. `docs/architecture/INVARIANTS.md`
4. `docs/cleanup/cleanup-inventory.md`
5. `CONTRIBUTING.md`

## Core Entry Points

- CLI: `bin/ossetup`
- Runner modules: `lib/runners/*.sh`
- Provider modules: `lib/providers/*.sh`
- Workspace contract: `.ossetup-workspace.json` (required for runtime commands)

## Data Ownership

- Core repo: engine/tests/docs only.
- Personal repo: runtime data (`manifests/`, `dotfiles/`, `functions/`, `hooks/`, `state/`).

## Allowed Mutation Surfaces

- Runtime/provider logic under `lib/`
- CLI contracts under `bin/ossetup`
- Tests under `tests/`
- Documentation under `docs/` and root `README.md`
- Personal-bootstrap guidance/scripts under runbooks/templates

## Verification Commands

```bash
bats tests
for f in $(rg --files -g '*.sh' bin lib hooks popos-migration/scripts tests) bin/ossetup; do bash -n "$f"; done
```

## Do Not Break

- Preview/apply mutation boundaries.
- Exit code semantics in `lib/core/common.sh`.
- Layered precedence in personal repo: `core -> target -> user -> host`.
- Workspace-required runtime behavior.
- Secrets policy (reference-only, no plaintext secrets in repo).
