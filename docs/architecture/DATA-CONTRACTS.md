# Data Contracts

## Purpose

Define contract boundaries for desired state and observed state snapshots in the layered-only model.

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

## Layer Merge Rules

1. Precedence is deterministic: `core -> target -> host`.
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

## Change Management

Any contract change requires synchronized updates in:

- `README.md`
- `docs/architecture/ARCHITECTURE.md`
- `docs/architecture/INVARIANTS.md`
- `CHANGELOG.md`
- related runbooks (`docs/runbooks/*`)
