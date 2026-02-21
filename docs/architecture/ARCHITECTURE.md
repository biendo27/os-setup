# OSSetup Architecture

## Goal

Provide repeatable, low-effort environment restore for Linux Debian/Ubuntu and macOS from a repository-managed configuration source.

## System Layout

- Entry CLI: `bin/ossetup`
- Shared runtime: `lib/core/common.sh`, `lib/core/workspace.sh`, `lib/core/manifest.sh`
- Layer resolver: `lib/core/layers.sh`
- Command orchestration: `lib/runners/*.sh`
- Domain providers: `lib/providers/*.sh`
- Declarative state:
  - Core repo:
    - Profiles: `manifests/profiles/*.yaml`
    - Layered desired state:
      - `manifests/layers/core.yaml`
      - `manifests/layers/targets/*.yaml`
      - `manifests/layers/hosts/*.yaml`
    - Dotfiles map: `manifests/dotfiles.yaml`
    - Secret references: `manifests/secrets.yaml`
  - Personal repo (personal-overrides mode):
    - Workspace config: `.ossetup-workspace.json`
    - User/host overlays:
      - `manifests/layers/users/*.yaml`
      - `manifests/layers/hosts/*.yaml`
    - Snapshots: `manifests/state/*`
- User utilities:
  - Zsh functions: `functions/*`
  - Migration utilities: `popos-migration/*`

## Command Lifecycle

1. `bin/ossetup` parses command/options and dispatches to runner.
2. Workspace resolver loads `.ossetup-workspace.json` (if present) and sets `single-repo` vs `personal-overrides` mode.
3. Runner resolves target/profile/host and validates prerequisites.
4. Runner acquires repository lock (`.ossetup.lock/`) for mutating flows.
5. Resolver builds effective target manifest:
   - single-repo: `core -> target -> host`
   - personal-overrides: `core -> target -> core-host -> user -> personal-host`
6. Runner calls providers in deterministic order.
7. Providers apply/sync/verify per manifest contracts.
8. Runner emits logs and exit codes via shared runtime helpers.

## Data Domains

- Desired state:
  - Core: `manifests/profiles/*.yaml`
  - Core: `manifests/layers/{core,targets,hosts}/*.yaml`
  - Core: `manifests/dotfiles.yaml`
  - Personal (optional): `manifests/layers/{users,hosts}/*.yaml`
- Observed state snapshots:
  - Single-repo: `manifests/state/<target>/*` in current repo
  - Personal-overrides: `manifests/state/<target>/*` in personal repo
- Validation/report outputs:
  - `reports/<timestamp>/*`

## Supported Boundaries

- Core automation contract is under `bin/`, `lib/`, `manifests/`, `tests/`, and root docs.
- `popos-migration/` is a supported utility set, but not a core `ossetup` command path.
- Removed/deprecated entrypoint history is tracked in `CHANGELOG.md` and cleanup inventory.

## Evolution Rules

- New behavior must be added behind explicit command contracts and tests.
- Layered manifest precedence stays deterministic:
  - single-repo: `core -> target -> host`
  - personal-overrides: `core -> target -> core-host -> user -> personal-host`
- Runtime contract is layered-only as of `v1.0.0`.
- Deprecated entrypoints must publish migration mapping before removal.
- Cleanup/removal must be tracked in `docs/cleanup/cleanup-inventory.md` before changes.
