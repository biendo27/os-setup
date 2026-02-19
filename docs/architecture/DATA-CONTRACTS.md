# Data Contracts

## Purpose

Define contract boundaries for repository-managed desired state, machine snapshots, and future layered manifests.

## Current Contracts

## Profiles (`manifests/profiles/*.yaml`)

- Scope: module toggles for install workflow.
- Contract:
  - `name` (string)
  - `description` (string, optional)
  - `modules` (object with boolean flags)
- Behavior:
  - Missing module keys default to disabled.
  - Unknown modules are ignored by runners unless wired in code.

## Targets (`manifests/targets/*.yaml`)

- Scope: target-specific package/tool declarations.
- Current contract:
  - `packages` object with provider arrays (e.g. `apt`, `flatpak`, `snap`, `brew`, `brew_cask`)
  - `npm_globals` array
- Behavior:
  - Provider arrays are consumed by target-specific provider modules.
  - Unknown providers are ignored unless explicitly consumed.

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
  - No plaintext secret values are stored in-repo.

## State Snapshots (`manifests/state/<target>/*`)

- Scope: observed machine state for comparison/audit.
- Contract:
  - text lists (one item per line) for package/app/global tool snapshots.
- Behavior:
  - Produced by `sync-all` state export provider.
  - Not the canonical source of desired state by default.

## Planned Layered Model (Roadmap)

- `manifests/layers/core.yaml`:
  - shared desired state across targets.
- `manifests/layers/targets/<target>.yaml`:
  - target-specific desired state overlays.
- `manifests/layers/hosts/<host-id>.yaml`:
  - host-specific overlay for machine-local needs.
- Merge precedence:
  - `core -> target -> host`.

## Compatibility Rules

1. Existing manifests remain supported during migration to layered model.
2. Migration must include adapter logic and contract tests.
3. Any contract change requires updates to:
   - `docs/architecture/ARCHITECTURE.md`
   - `docs/architecture/INVARIANTS.md`
   - `README.md`
   - `CHANGELOG.md`
