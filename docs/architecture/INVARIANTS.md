# OSSetup Invariants

## Runtime Invariants

- `INV-001`: All executable bash entrypoints use `set -euo pipefail`.
- `INV-002`: Commands that mutate repo state must pass through lock acquisition (`acquire_lock`).
- `INV-003`: Unknown CLI options/commands exit with usage error code (`E_USAGE`).
- `INV-004`: Runtime commands require `.ossetup-workspace.json`.

## Layering and Manifest Invariants

- `INV-010`: Effective desired state resolves with deterministic precedence: `core -> target -> user -> host`.
- `INV-011`: Layered manifests (`core` + target layer) are required in personal repo.
- `INV-012`: Array merge behavior for layered manifests is ordered union with de-duplication.
- `INV-013`: `install --host auto` resolves from normalized hostname; explicit host ids must match `[a-z0-9][a-z0-9._-]{0,62}`.
- `INV-014`: Workspace config must include valid `core_repo_path` and `user_id`.
- `INV-015`: Runtime data resolution is personal-repo-only (no core data fallback).

## Sync/Promote/Verify Invariants

- `INV-020`: `sync --preview` never mutates repository files.
- `INV-021`: `sync --apply` mutates only mapped personal dotfiles/functions and rejects apply when executed from core repo path.
- `INV-022`: `sync-all --scope config` mutates config only; `--scope state` mutates state/user-layer only; `--scope all` does both in personal repo.
- `INV-023`: `promote --preview` never mutates manifests.
- `INV-024`: `promote --apply` mutates personal `manifests/layers/targets/<target>.yaml` only.
- `INV-025`: `verify --strict` fails when personal state snapshots drift from resolved manifest contracts.

## Security Invariants

- `INV-030`: Repository stores secret references only; no secret plaintext is committed.
- `INV-031`: Bitwarden checks validate references, not secret values.
- `INV-032`: Install hooks resolve from personal repo `hooks/pre-install.d` and `hooks/post-install.d` only.

## Compatibility and Cleanup Invariants

- `INV-040`: Public-facing deprecated scripts must emit warnings before eventual removal.
- `INV-041`: Removal candidates require inventory entry with classification and impact assessment.
- `INV-042`: If safety cannot be proven with tests and references, item is not removed.
- `INV-043`: Runtime does not read from legacy `manifests/targets/*.yaml`.

## Documentation Invariants

- `INV-050`: README links to canonical architecture, invariants, agent context, cleanup inventory, and contribution docs.
- `INV-051`: Cleanup inventory and changelog stay in sync with repository changes.
