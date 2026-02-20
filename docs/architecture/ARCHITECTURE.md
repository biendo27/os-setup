# OSSetup Architecture

## Goal

Provide repeatable, low-effort environment restore for Linux Debian/Ubuntu and macOS from a repository-managed configuration source.

## System Layout

- Entry CLI: `bin/ossetup`
- Shared runtime: `lib/core/common.sh`, `lib/core/manifest.sh`
- Layer resolver: `lib/core/layers.sh`
- Command orchestration: `lib/runners/*.sh`
- Domain providers: `lib/providers/*.sh`
- Declarative state:
  - Profiles: `manifests/profiles/*.yaml`
  - Layered desired state:
    - `manifests/layers/core.yaml`
    - `manifests/layers/targets/*.yaml`
    - `manifests/layers/hosts/*.yaml`
  - Legacy targets (compat adapter window): `manifests/targets/*.yaml`
  - Dotfiles map: `manifests/dotfiles.yaml`
  - Secret references: `manifests/secrets.yaml`
  - Snapshots: `manifests/state/*`
- User utilities:
  - Zsh functions: `functions/*`
  - Migration utilities: `popos-migration/*`

## Command Lifecycle

1. `bin/ossetup` parses command/options and dispatches to runner.
2. Runner resolves target/profile/host and validates prerequisites.
3. Runner acquires repository lock (`.ossetup.lock/`) for mutating flows.
4. Resolver builds effective target manifest from `core -> target -> host` (or legacy adapter fallback).
5. Runner calls providers in deterministic order.
6. Providers apply/sync/verify per manifest contracts.
7. Runner emits logs and exit codes via shared runtime helpers.

## Data Domains

- Desired state:
  - `manifests/profiles/*.yaml`
  - `manifests/layers/{core,targets,hosts}/*.yaml`
  - `manifests/targets/*.yaml` (legacy compatibility source)
  - `manifests/dotfiles.yaml`
- Observed state snapshots:
  - `manifests/state/<target>/*`
- Validation/report outputs:
  - `reports/<timestamp>/*`

## Supported Boundaries

- Core automation contract is under `bin/`, `lib/`, `manifests/`, `tests/`, and root docs.
- `popos-migration/` is a supported utility set, but not a core `ossetup` command path.
- Removed/deprecated entrypoint history is tracked in `docs/deprecations.md`.

## Evolution Rules

- New behavior must be added behind explicit command contracts and tests.
- Layered manifest precedence stays `core -> target -> host`.
- Adapter fallback from legacy manifests remains through `v0.4.0` and is removable earliest `v0.5.0`.
- Deprecated entrypoints must publish migration mapping before removal.
- Cleanup/removal must be tracked in `docs/cleanup/cleanup-inventory.md` before changes.
