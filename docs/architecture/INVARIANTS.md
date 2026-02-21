# OSSetup Invariants

## Runtime Invariants

- `INV-001`: All executable bash entrypoints use `set -euo pipefail`.
- `INV-002`: Commands that mutate repo state must pass through lock acquisition (`acquire_lock`).
- `INV-003`: Unknown CLI options/commands exit with usage error code (`E_USAGE`).

## Layering and Manifest Invariants

- `INV-010`: Effective desired state resolves with deterministic precedence:
  - single-repo: `core -> target -> host`
  - personal-overrides: `core -> target -> core-host -> user -> personal-host`
- `INV-011`: Layered manifests are required for runtime (`core` + target layer must exist).
- `INV-012`: Array merge behavior for layered manifests is ordered union with de-duplication.
- `INV-013`: `install --host auto` resolves from normalized hostname; explicit host ids must match `[a-z0-9][a-z0-9._-]{0,62}`.
- `INV-014`: In `personal-overrides` mode, workspace config must include valid `core_repo_path` and `user_id`.

## Sync/Promote/Verify Invariants

- `INV-020`: `sync --preview` never mutates repository files.
- `INV-021`: `sync --apply` mutates only mapped dotfiles/functions in write repo:
  - single-repo: current repo
  - personal-overrides: personal repo only
- `INV-022`: `sync-all --scope config` mutates config only; `--scope state` mutates state/manifest only; `--scope all` does both in write repo.
- `INV-023`: `promote --preview` never mutates manifests.
- `INV-024`: `promote --apply` mutates only `manifests/layers/targets/<target>.yaml` in single-repo mode; in personal-overrides mode, `--apply` is blocked.
- `INV-025`: `verify --strict` fails when state snapshots drift from resolved manifest contracts.

## Security Invariants

- `INV-030`: Repository stores secret references only; no secret plaintext is committed.
- `INV-031`: Bitwarden checks validate references, not secret values.
- `INV-032`: Install hooks must remain explicit scripts under `hooks/pre-install.d` and `hooks/post-install.d`.

## Compatibility and Cleanup Invariants

- `INV-040`: Public-facing deprecated scripts must emit warnings before eventual removal.
- `INV-041`: Removal candidates require inventory entry with classification and impact assessment.
- `INV-042`: If safety cannot be proven with tests and references, item is not removed.
- `INV-043`: Runtime does not read from `manifests/targets/*.yaml` (`v1.0.0` layered-only cutover).

## Documentation Invariants

- `INV-050`: README links to canonical architecture, invariants, agent context, cleanup inventory, and contribution docs.
- `INV-051`: Cleanup inventory and changelog stay in sync with repository changes.
