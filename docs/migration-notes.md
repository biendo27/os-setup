# Migration Notes

Last updated: 2026-02-19

## Legacy Command Mapping

| Legacy entrypoint | Current entrypoint | Notes |
| --- | --- | --- |
| `bin/setup.sh` | `bin/ossetup install` | Shim remains active during deprecation window |
| `bin/sync-from-home.sh` | `bin/ossetup sync --apply` | Shim remains active during deprecation window |
| `bin/setup-zsh-functions.sh` | `bin/ossetup install` | Legacy utility retained short-term for compatibility |

## Non-Breaking Cleanup in This Batch

1. Removed unused helper `json_read()` from `lib/core/common.sh`.
2. Removed redundant `backup` fields from `manifests/dotfiles.yaml`.
3. Added contract/dead-reference/docs-consistency tests to prevent regressions.

## Operator Guidance

Use this sequence on new or migrated machines:

```bash
./bin/ossetup doctor
./bin/ossetup install --profile default --target auto
./bin/ossetup verify --report
```
