# OSSetup Architecture

## Goal

Provide repeatable, low-effort environment restore for Linux Debian/Ubuntu and macOS with a strict `core engine + personal data` model.

## System Layout

- Entry CLI: `bin/ossetup`
- Shared runtime: `lib/core/common.sh`, `lib/core/workspace.sh`, `lib/core/manifest.sh`
- Layer resolver: `lib/core/layers.sh`
- Command orchestration: `lib/runners/*.sh`
- Domain providers: `lib/providers/*.sh`

Data ownership:

- Core repo (`OSSetup`): engine code, tests, docs.
- Personal repo (`emanon-ossync` style): runtime data.
  - Workspace config: `.ossetup-workspace.json`
  - Desired state: `manifests/profiles/*.yaml`, `manifests/layers/{core,targets,users,hosts}/*.yaml`
  - Dotfiles map: `manifests/dotfiles.yaml`
  - Secret references: `manifests/secrets.yaml`
  - Snapshots: `manifests/state/*`
  - Runtime assets: `dotfiles/*`, `functions/*`, `hooks/{pre-install.d,post-install.d}/*`

## Command Lifecycle

1. `bin/ossetup` parses command/options.
2. For runtime commands (`install`, `sync`, `sync-all`, `promote`, `verify`, `doctor`, `bootstrap`), workspace config is required.
3. Workspace resolver sets:
   - engine root: `OSSETUP_ROOT` (core)
   - data root: personal repo from `.ossetup-workspace.json`
4. Runner resolves target/profile/host and validates prerequisites.
5. Runner acquires lock under personal repo for mutating flows.
6. Resolver builds effective desired state from personal layers:
   - `core -> target -> user -> host`
7. Runner calls providers in deterministic order.
8. Providers apply/sync/verify using personal repo data paths only.

## Data Domains

- Desired state (personal repo): layered manifests + profile toggles + dotfiles/secrets contracts.
- Observed state (personal repo): `manifests/state/<target>/*`.
- Validation/report outputs (personal repo): `reports/<timestamp>/*`.

## Supported Boundaries

- Runtime must not depend on core repo `manifests/*`, `dotfiles/*`, `functions/*`, or `hooks/*`.
- Core repo may keep templates/examples for bootstrap guidance, but runtime never resolves data from template paths.
- `popos-migration/` remains a utility set, not a core `ossetup` command path.

## Evolution Rules

- New behavior must be added behind explicit command contracts and tests.
- Layer precedence remains deterministic: `core -> target -> user -> host`.
- Workspace contract is mandatory for runtime commands.
- Cleanup/removal must be tracked in `docs/cleanup/cleanup-inventory.md` before changes.
