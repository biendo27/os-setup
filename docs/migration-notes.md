# Migration Notes

Last updated: 2026-02-20

## Legacy Command Mapping

| Legacy entrypoint | Current entrypoint | Notes |
| --- | --- | --- |
| `bin/setup.sh` | `bin/ossetup install` | Legacy shim removed on 2026-02-19 |
| `bin/sync-from-home.sh` | `bin/ossetup sync --apply` | Legacy shim removed on 2026-02-19 |
| `bin/setup-zsh-functions.sh` | `bin/ossetup install` | Legacy shim removed on 2026-02-19 |

## Layered Manifest Migration

Current model is layered-first with compatibility fallback:

1. Primary desired-state files:
   - `manifests/layers/core.yaml`
   - `manifests/layers/targets/<target>.yaml`
   - `manifests/layers/hosts/<host-id>.yaml`
2. Fallback desired-state files (temporary):
   - `manifests/targets/<target>.yaml`
3. Merge precedence:
   - `core -> target -> host`

## Compatibility Window

1. Adapter introduced in `v0.3.0`.
2. Adapter retained through `v0.4.0`.
3. Earliest adapter removal target is `v0.5.0`, after migration tests and dead-reference checks are green.

## New Command Contracts

- `ossetup install --host <id|auto>`
- `ossetup sync-all --scope config|state|all`
- `ossetup promote --target <target> --scope packages|npm_globals|all --from-state latest|<dir> --preview|--apply`
- `ossetup verify --strict`

## Operator Guidance

Preferred sequence on a new or migrated machine:

```bash
./bin/ossetup doctor
./bin/ossetup install --profile default --target auto --host auto
./bin/ossetup sync-all --apply --target auto --scope all
./bin/ossetup verify --strict --report
```
