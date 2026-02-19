# OSSetup Architecture

## Goal

Provide repeatable, low-effort environment restore for Linux Debian/Ubuntu and macOS from a repository-managed configuration source.

## System Layout

- Entry CLI: `bin/ossetup`
- Shared runtime: `lib/core/common.sh`, `lib/core/manifest.sh`
- Command orchestration: `lib/runners/*.sh`
- Domain providers: `lib/providers/*.sh`
- Declarative state:
  - Profiles: `manifests/profiles/*.yaml`
  - Targets: `manifests/targets/*.yaml`
  - Dotfiles map: `manifests/dotfiles.yaml`
  - Secret references: `manifests/secrets.yaml`
  - Snapshots: `manifests/state/*`
- User utilities:
  - Zsh functions: `functions/*`
  - Migration utilities: `popos-migration/*`

## Command Lifecycle

1. `bin/ossetup` parses command/options and dispatches to runner.
2. Runner resolves target/profile and validates prerequisites.
3. Runner acquires repository lock (`.ossetup.lock/`) for mutating flows.
4. Runner calls providers in deterministic order.
5. Providers apply/sync/verify per manifest contracts.
6. Runner emits logs and exit codes via shared runtime helpers.

## Data Domains

- Desired state:
  - `manifests/profiles/*.yaml`
  - `manifests/targets/*.yaml`
  - `manifests/dotfiles.yaml`
- Observed state snapshots:
  - `manifests/state/<target>/*`
- Validation/report outputs:
  - `reports/<timestamp>/*`

## Supported Boundaries

- Core automation contract is under `bin/`, `lib/`, `manifests/`, `tests/`, and root docs.
- `popos-migration/` is a supported utility set, but not a core `ossetup` command path.
- Legacy shims are temporary compatibility surfaces and tracked in `docs/deprecations.md`.

## Evolution Rules

- New behavior must be added behind explicit command contracts and tests.
- Deprecated entrypoints must keep shim behavior for at least one release window.
- Cleanup/removal must be tracked in `docs/cleanup/cleanup-inventory.md` before changes.
