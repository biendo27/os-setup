# Deprecations Log

Last updated: 2026-02-19

## Active Deprecations

No active deprecations currently.

## Completed Removals

| Item | Status | Replacement | Started | Planned Removal |
| --- | --- | --- | --- | --- |
| `bin/setup.sh` | Removed after deprecation | `bin/ossetup install` | 2026-02-19 | Removed 2026-02-19 |
| `bin/sync-from-home.sh` | Removed after deprecation | `bin/ossetup sync --apply` | 2026-02-19 | Removed 2026-02-19 |
| `bin/setup-zsh-functions.sh` | Removed after deprecation | `bin/ossetup install` (functions module) | 2026-02-19 | Removed 2026-02-19 |

## Policy

1. Public entrypoints should be deprecated with migration mapping before removal.
2. Every deprecation requires:
   - warning in command output,
   - migration mapping in `docs/migration-notes.md`,
   - cleanup inventory tracking in `docs/cleanup/cleanup-inventory.md`,
   - contract test coverage.
