# OSSetup Invariants

## Runtime Invariants

- `INV-001`: All executable bash entrypoints use `set -euo pipefail`.
- `INV-002`: Commands that mutate repo state must pass through lock acquisition (`acquire_lock`).
- `INV-003`: Unknown CLI options/commands exit with usage error code (`E_USAGE`).

## State and Sync Invariants

- `INV-010`: `sync --preview` never mutates repository files.
- `INV-011`: `sync --apply` mutates only mapped dotfiles/functions.
- `INV-012`: `sync-all --preview` never mutates manifests.
- `INV-013`: `sync-all --apply` may refresh snapshot files in `manifests/state/*`.
- `INV-014`: Dotfile path mappings are sourced from `manifests/dotfiles.yaml` only.

## Security Invariants

- `INV-020`: Repository stores secret references only; no secret plaintext is committed.
- `INV-021`: Bitwarden checks validate references, not secret values.
- `INV-022`: Install hooks must remain explicit scripts under `hooks/pre-install.d` and `hooks/post-install.d`.

## Compatibility and Cleanup Invariants

- `INV-030`: Public-facing deprecated scripts must emit warnings before eventual removal.
- `INV-031`: Removal candidates require inventory entry with classification and impact assessment.
- `INV-032`: If safety cannot be proven with tests and references, item is not removed.

## Documentation Invariants

- `INV-040`: README links to canonical architecture, invariants, agent context, cleanup inventory, and contribution docs.
- `INV-041`: Cleanup, deprecation, and migration traceability docs stay in sync with repository changes.
