# Deprecations Log

Last updated: 2026-02-19

## Active Deprecations

| Item | Status | Replacement | Started | Planned Removal |
| --- | --- | --- | --- | --- |
| `bin/setup.sh` | Deprecated, kept as shim | `bin/ossetup install` | 2026-02-19 | After one release window |
| `bin/sync-from-home.sh` | Deprecated, kept as shim | `bin/ossetup sync --apply` | 2026-02-19 | After one release window |
| `bin/setup-zsh-functions.sh` | Deprecated utility, compatibility retained | `bin/ossetup install` (functions module) | 2026-02-19 | After one release window and migration verification |

## Policy

1. Public entrypoints are not removed immediately.
2. Every deprecation requires:
   - warning in command output,
   - migration mapping in `docs/migration-notes.md`,
   - cleanup inventory tracking in `docs/cleanup/cleanup-inventory.md`,
   - contract test coverage.
