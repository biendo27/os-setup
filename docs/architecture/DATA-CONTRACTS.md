# Data Contracts

## Purpose

Define contract boundaries for desired state and observed state snapshots in layered runtime modes.

## Workspace Config (`.ossetup-workspace.json`)

- Scope: enables `personal-overrides` mode from a personal repo.
- Contract:
  - `schema_version` (number)
  - `mode` (`personal-overrides` | other/absent -> single-repo)
  - `core_repo_path` (string, required in `personal-overrides`)
  - `user_id` (string, required in `personal-overrides`)
  - `core_repo_url` (string, optional metadata)
  - `core_repo_ref` (string, optional metadata)
- Behavior:
  - CLI auto-discovers this file from current directory upward.
  - `OSSETUP_WORKSPACE_FILE` can point to an explicit file path.

## Profiles (`manifests/profiles/*.yaml`)

- Scope: module toggles for install workflow.
- Contract:
  - `name` (string)
  - `description` (string, optional)
  - `modules` (object with boolean flags)
- Behavior:
  - Missing module keys default to disabled.
  - Unknown modules are ignored by runners unless wired in code.

## Layered Desired State (Primary)

## Core Layer (`manifests/layers/core.yaml`)

- Scope: shared baseline across all targets/hosts.
- Contract:
  - `packages` object (optional provider arrays)
  - `npm_globals` array

## Target Layers (`manifests/layers/targets/<target>.yaml`)

- Scope: OS/target-specific desired state.
- Contract:
  - `packages` object with provider arrays:
    - Linux: `apt`, `flatpak`, `snap`
    - macOS: `brew`, `brew_cask`
  - `npm_globals` array

## Host Layers (`manifests/layers/hosts/<host-id>.yaml`)

- Scope: machine-specific overlay.
- Contract:
  - Same shape as target layer for overridden or additive values.
- Host id contract:
  - normalized lowercase
  - regex: `[a-z0-9][a-z0-9._-]{0,62}`

## Personal User Layer (`manifests/layers/users/<user-id>.yaml`)

- Scope: user-specific overlay in `personal-overrides` mode.
- Contract:
  - Same shape as target/core layer (`packages`, `npm_globals`, optional metadata keys).

## Personal Host Layer (`manifests/layers/hosts/<host-id>.yaml` in personal repo)

- Scope: machine-specific overlay in `personal-overrides` mode.
- Contract:
  - Same shape as target/core layer (`packages`, `npm_globals`, optional metadata keys).

## Layer Merge Rules

1. Precedence is deterministic:
   - single-repo: `core -> target -> host`
   - personal-overrides: `core -> target -> core-host -> user -> personal-host`
2. Object values merge recursively.
3. Array values merge by ordered union (left to right, de-duplicated).
4. Scalar/non-object values from later layer override earlier layer.

## Dotfiles (`manifests/dotfiles.yaml`)

- Scope: file/dir sync and apply mapping between repo and home.
- Contract:
  - `entries[]`:
    - `repo` (path, required)
    - `home` (path, required, supports `~`)
    - `type` (`file` | `dir`, optional, default `file`)
    - `mode` (file mode string, optional for `file`)
    - `optional` (boolean, optional, default `false`)
  - `functions`:
    - `repo_dir`
    - `home_dir`

## Secrets (`manifests/secrets.yaml`)

- Scope: reference-only secret validation.
- Contract:
  - `entries[]`:
    - `item` (vault item key)
    - `required` (boolean, default true)
- Invariant:
  - no plaintext secret values are stored in-repo.

## State Snapshots (`manifests/state/<target>/*`)

- Scope: observed machine state for comparison/audit/promote.
- Contract:
  - text lists (one item per line) for package/app/global tool snapshots.
  - Linux snapshot files:
    - `apt-manual.txt`
    - `flatpak-apps.txt`
    - `snap-list.txt`
    - `npm-globals.txt`
  - macOS snapshot files:
    - `brew-formula.txt`
    - `brew-casks.txt`
    - `npm-globals.txt`
- Behavior:
  - produced by `sync-all` state export provider.
  - consumed by `promote` and `verify --strict`.
  - in `personal-overrides` mode, snapshots are read/written from personal repo.

## Change Management

Any contract change requires synchronized updates in:

- `README.md`
- `docs/architecture/ARCHITECTURE.md`
- `docs/architecture/INVARIANTS.md`
- `CHANGELOG.md`
- related runbooks (`docs/runbooks/*`)
