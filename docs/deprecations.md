# Deprecations Log

Last updated: 2026-02-20

## Active Deprecations

| Item | Status | Replacement | Started | Planned Removal |
| --- | --- | --- | --- | --- |
| `manifests/targets/*.yaml` (legacy desired-state source) | Deprecated compatibility path | `manifests/layers/{core,targets,hosts}/*.yaml` | 2026-02-20 (`v0.3.0`) | Earliest `v0.5.0` |

## Completed Removals

| Item | Status | Replacement | Started | Planned Removal |
| --- | --- | --- | --- | --- |
| `bin/setup.sh` | Removed after deprecation | `bin/ossetup install` | 2026-02-19 | Removed 2026-02-19 |
| `bin/sync-from-home.sh` | Removed after deprecation | `bin/ossetup sync --apply` | 2026-02-19 | Removed 2026-02-19 |
| `bin/setup-zsh-functions.sh` | Removed after deprecation | `bin/ossetup install` (functions module) | 2026-02-19 | Removed 2026-02-19 |

## Policy

1. Public entrypoints or data contracts should be deprecated with migration mapping before removal.
2. Every deprecation requires:
   - warning in command output (if command-facing),
   - migration mapping in `docs/migration-notes.md`,
   - cleanup inventory tracking in `docs/cleanup/cleanup-inventory.md`,
   - contract test coverage.
3. Compatibility adapters are removed only after safety proofs are green (`bats`, dead-reference, docs consistency, CI matrix).
