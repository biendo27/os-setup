# Data Contracts

## Purpose

Define the runtime contracts for personal-only data mode.

## Workspace Config (`.ossetup-workspace.json`)

- Scope: required for runtime command execution.
- Contract:
  - `schema_version` (number)
  - `mode` (`personal-only` required; `personal-overrides` accepted as alias)
  - `core_repo_path` (string, required)
  - `user_id` (string, required)
  - `core_repo_url` (string, optional metadata)
  - `core_repo_ref` (string, optional metadata)
- Behavior:
  - CLI auto-discovers this file from current directory upward.
  - `OSSETUP_WORKSPACE_FILE` can point to an explicit file path.
  - Missing workspace file is a precheck failure.

## Profiles (`manifests/profiles/*.yaml`)

- Scope: module toggles for install workflow.
- Contract:
  - `name` (string)
  - `description` (string, optional)
  - `modules` (object with boolean flags)

## Layered Desired State (Personal Repo)

### Core Layer (`manifests/layers/core.yaml`)

- Shared baseline.
- Contract:
  - `packages` object (optional provider arrays)
  - `npm_globals` array

### Target Layers (`manifests/layers/targets/<target>.yaml`)

- OS/target-specific desired state.
- Contract:
  - `packages` object:
    - Linux: `apt`, `flatpak`, `snap`
    - macOS: `brew`, `brew_cask`
  - `npm_globals` array

### User Layer (`manifests/layers/users/<user-id>.yaml`)

- User-specific overlay.
- Contract: same shape as target/core layer.

### Host Layer (`manifests/layers/hosts/<host-id>.yaml`)

- Machine-specific overlay.
- Contract: same shape as target/core layer.
- Host id regex: `[a-z0-9][a-z0-9._-]{0,62}`

## Layer Merge Rules

1. Precedence is deterministic: `core -> target -> user -> host`.
2. Object values merge recursively.
3. Array values merge by ordered union (left to right, de-duplicated).
4. Scalars from later layers override earlier layers.

## Dotfiles (`manifests/dotfiles.yaml`)

- Scope: sync/apply mapping between personal repo and HOME.
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
- Invariant: no plaintext secret values are stored in-repo.

## State Snapshots (`manifests/state/<target>/*`)

- Scope: observed machine state for comparison/audit/promote.
- Files:
  - Linux: `apt-manual.txt`, `flatpak-apps.txt`, `snap-list.txt`, `npm-globals.txt`
  - macOS: `brew-formula.txt`, `brew-casks.txt`, `npm-globals.txt`
- Behavior:
  - produced by `sync-all --scope state`
  - consumed by `promote` and `verify --strict`
  - read/write location is always personal repo

## Change Management

Any contract change requires synchronized updates in:

- `README.md`
- `docs/architecture/ARCHITECTURE.md`
- `docs/architecture/INVARIANTS.md`
- `CHANGELOG.md`
- related runbooks (`docs/runbooks/*`)
