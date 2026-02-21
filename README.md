# OSSetup

Declarative bootstrap for your full developer experience on Linux Debian/Ubuntu and macOS.

Uses personal-only runtime:

- Core repo: engine and tests/docs
- Personal repo: all runtime data (manifests, dotfiles, hooks, functions, state)

## One-liner bootstrap

```bash
curl -fsSL https://raw.githubusercontent.com/biendo27/os-setup/main/bin/raw-bootstrap.sh | bash
```

Default behavior of the core bootstrap script:

- clone/update core repo
- scaffold a local personal workspace at `~/.local/share/ossetup-personal` (if missing)
- run `install` from the personal workspace context

You can pin core repo/ref with env vars:

```bash
OSSETUP_CORE_REPO_URL="https://github.com/biendo27/os-setup.git" \
OSSETUP_CORE_REPO_REF="main" \
curl -fsSL https://raw.githubusercontent.com/biendo27/os-setup/main/bin/raw-bootstrap.sh | bash
```

If you already have a personal repo bootstrap script, delegate to it:

```bash
OSSETUP_PERSONAL_REPO_URL="https://github.com/<your-user>/<your-personal-repo>.git" \
OSSETUP_PERSONAL_REPO_REF="main" \
curl -fsSL https://raw.githubusercontent.com/biendo27/os-setup/main/bin/raw-bootstrap.sh | bash
```

## Personal-Only Mode (`core + personal`)

Personal-only mode keeps all runtime sync data in your personal repo.

Create a workspace config in your personal repo root:

```json
{
  "schema_version": 1,
  "core_repo_url": "https://github.com/biendo27/os-setup.git",
  "core_repo_ref": "main",
  "core_repo_path": "../OSSetup",
  "user_id": "emanon",
  "mode": "personal-only"
}
```

Runtime behavior in this mode:

- `install` reads merged desired state from `core -> target -> user -> host` (all layer files in personal repo).
- `sync --apply` writes only to personal repo.
- `sync-all --scope state --apply` writes state snapshots to personal repo and updates personal user layer.
- `promote --apply` updates personal `manifests/layers/targets/<target>.yaml`.
- `verify --strict` compares merged manifest against personal state snapshots.

Runtime commands require `.ossetup-workspace.json` (`install`, `sync`, `sync-all`, `promote`, `verify`, `doctor`).
Legacy mode value `personal-overrides` is accepted as an alias for `personal-only`.

## Local usage

Run runtime commands from your personal repo directory.

```bash
ossetup help
ossetup doctor
ossetup install --profile default --target auto --host auto
ossetup sync --preview
ossetup sync --apply
ossetup sync-all --apply --target auto --scope all
ossetup promote --target auto --scope all --from-state latest --preview
ossetup promote --target auto --scope all --from-state latest --apply
ossetup update-globals
ossetup verify --report
ossetup verify --strict --report
ossetup doctor --require-global
```

Developer-only utilities in core repo:

```bash
./bin/migrate-npm-globals-to-mise.sh
```

## Documentation Index

- Architecture: [`docs/architecture/ARCHITECTURE.md`](docs/architecture/ARCHITECTURE.md)
- Invariants: [`docs/architecture/INVARIANTS.md`](docs/architecture/INVARIANTS.md)
- Data contracts: [`docs/architecture/DATA-CONTRACTS.md`](docs/architecture/DATA-CONTRACTS.md)
- Agent handoff context: [`docs/agents/AGENT_CONTEXT.md`](docs/agents/AGENT_CONTEXT.md)
- Cleanup inventory: [`docs/cleanup/cleanup-inventory.md`](docs/cleanup/cleanup-inventory.md)
- Runbooks:
  - [`docs/runbooks/DEBUGGING.md`](docs/runbooks/DEBUGGING.md)
  - [`docs/runbooks/PERSONAL-WORKSPACE.md`](docs/runbooks/PERSONAL-WORKSPACE.md)
  - [`docs/runbooks/RELEASE.md`](docs/runbooks/RELEASE.md)
- ADR roadmap:
  - [`docs/adr/ADR-0001-manifest-layering-roadmap.md`](docs/adr/ADR-0001-manifest-layering-roadmap.md)
  - [`docs/adr/ADR-0002-command-contract-expansion-roadmap.md`](docs/adr/ADR-0002-command-contract-expansion-roadmap.md)
- Phase 3-4 execution roadmap: [`docs/plans/2026-02-19-phase3-4-execution-roadmap.md`](docs/plans/2026-02-19-phase3-4-execution-roadmap.md)
- Contribution guide: [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Changelog: [`CHANGELOG.md`](CHANGELOG.md)
- License: [`LICENSE`](LICENSE)

## Release and Changelog

- Versioning uses Semantic Versioning (`vMAJOR.MINOR.PATCH`).
- Changelog format follows Keep a Changelog in [`CHANGELOG.md`](CHANGELOG.md).
- Release procedure is documented in [`docs/runbooks/RELEASE.md`](docs/runbooks/RELEASE.md).
- Release integrity policy requires publishing:
  - `SHA256SUMS`
  - `SHA256SUMS.asc` (detached GPG signature of checksum file)
  - `RELEASE-PUBLIC-KEY.asc` (ASCII-armored public key for signature verification)
- Git workflow policy (trunk-based, PR-only, merge-commit) is in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Commands

- `bootstrap`: delegates to `install`
- `install`: installs packages, dotfiles, functions, mise, Android SDK, npm globals, and Bitwarden checks
  - `--host <id|auto>` resolves host overlay (`auto` uses normalized hostname)
- `sync`: syncs local HOME config back into repo (`--preview` by default)
  - Writes only to personal repo and rejects `--apply` when run from core repo.
- `sync-all`: runs `sync` and/or refreshes software manifests from the current machine
  - `--scope config|state|all` (default `all`)
  - State files are written under personal `manifests/state/<target>/*`.
- `promote`: promotes captured `manifests/state/<target>/*` snapshots into `manifests/layers/targets/<target>.yaml`
  - `--preview` shows plan only, `--apply` writes manifests
  - `--apply` writes to personal target layer.
- `update-globals`: updates global packages managed by `npm`, `pnpm`, `yarn`, `pipx`, and `dart pub global`
  - Supports `--dry-run` to preview commands without executing
  - Interactive confirmation `[Y/n]` (default Yes), use `-y`/`--yes` to skip prompts
- `verify`: validates current machine state against repo and writes report in `reports/<timestamp>/verify-report.txt`
  - `--strict` also enforces state/manifest drift checks
- `doctor`: validates manifests and local prerequisites
  - `--require-global` also verifies global `ossetup` shim at `~/.local/bin/ossetup`
- `bin/migrate-npm-globals-to-mise.sh`: imports all current `npm -g` packages into the `mise npm:` backend and runs `mise reshim`
- `bin/release-checksums.sh`: generates deterministic `SHA256SUMS` and optional GPG signature
- `bin/release-verify.sh`: verifies `SHA256SUMS` + `SHA256SUMS.asc` against release artifacts

## Update Strategy

`functions/update-all` in your personal repo now follows a mise-first workflow for developer tools:

1. System updates: `apt` (if available) and `snap`
2. Toolchain updates: `mise upgrade --yes`
3. Shim refresh: `mise reshim`

It intentionally does **not** run `npm update -g` anymore.

If you use zsh functions from your personal repo, `functions/update-globals` delegates to:

```bash
ossetup update-globals
```

Manifest files use JSON-compatible YAML syntax and live under personal repo:

- `manifests/profiles/*.yaml`
- `manifests/layers/core.yaml`
- `manifests/layers/targets/*.yaml`
- `manifests/layers/hosts/*.yaml`

In personal-only mode, personal repo can also include:

- `manifests/layers/users/<user-id>.yaml`
- `manifests/state/<target>/*`

## Global Command

`install` now installs a user-level shim at `~/.local/bin/ossetup` and ensures your `~/.zshrc` has:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

After first install, restart shell (or run `source ~/.zshrc`) and use:

```bash
ossetup help
```

## Canonical dotfiles

Managed via personal `manifests/dotfiles.yaml` and backed up before overwrite:

- `dotfiles/.zshrc` <-> `~/.zshrc`
- `dotfiles/.zimrc` <-> `~/.zimrc`
- `dotfiles/.config/starship.toml` <-> `~/.config/starship.toml`
- `dotfiles/.config/mise/config.toml` <-> `~/.config/mise/config.toml`
- `dotfiles/.ssh/config` <-> `~/.ssh/config`
- VS Code settings/keybindings
- VS Code profiles (`~/.config/Code/User/profiles`)
- Cursor profiles (`~/.config/Cursor/User/profiles`)
- Antigravity profiles (`~/.config/Antigravity/User/profiles`)
- `functions/*` <-> `~/.config/zsh/functions/*`

Core repo keeps sample personal data under `templates/personal-data/` for tests and bootstrap guidance only.

## Controlled Cleanup

Cleanup is tracked in [`docs/cleanup/cleanup-inventory.md`](docs/cleanup/cleanup-inventory.md) with three classes:

- `remove-now`: safe to remove immediately (unreferenced, replaced, covered by tests)
- `archive-first`: historical or compatibility-sensitive; archive first when still needed for context
- `keep`: still part of supported architecture

## Removed legacy shims

The following wrappers were removed after deprecation window review:

- `bin/setup.sh` -> use `bin/ossetup install`
- `bin/sync-from-home.sh` -> use `bin/ossetup sync --apply`
- `bin/setup-zsh-functions.sh` -> use `bin/ossetup install`

## Testing

```bash
bats tests
for f in $(rg --files -g '*.sh' bin lib hooks popos-migration/scripts tests) bin/ossetup; do bash -n "$f"; done
for f in manifests/*.yaml manifests/profiles/*.yaml manifests/layers/core.yaml manifests/layers/targets/*.yaml; do jq -e . "$f" >/dev/null; done
```

## License

This project is licensed under the MIT License. See [`LICENSE`](LICENSE).
