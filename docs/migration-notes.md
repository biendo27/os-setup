# Migration Notes

Last updated: 2026-02-20 (Phase 4 prep)

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
3. Final adapter and legacy-manifest removal is scheduled for `v1.0.0` hard cutover.

## New Command Contracts

- `ossetup install --host <id|auto>`
- `ossetup sync-all --scope config|state|all`
- `ossetup promote --target <target> --scope packages|npm_globals|all --from-state latest|<dir> --preview|--apply`
- `ossetup verify --strict`

## Final Pre-Cutover Checklist (`v1.0.0`)

1. Ensure layered manifests exist for every supported target:
   - `manifests/layers/core.yaml`
   - `manifests/layers/targets/linux-debian.yaml`
   - `manifests/layers/targets/macos.yaml`
2. Validate layered install path:
   - `OSSETUP_REQUIRE_LAYERED=1 ./bin/ossetup install --dry-run --target auto --profile default`
3. Ensure no hidden runtime dependence on `manifests/targets/*.yaml`.

## Operator Guidance

Preferred sequence on a new or migrated machine:

```bash
./bin/ossetup doctor
./bin/ossetup install --profile default --target auto --host auto
./bin/ossetup sync-all --apply --target auto --scope all
./bin/ossetup verify --strict --report
```
