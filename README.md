# OSSetup v2

Declarative bootstrap for your full developer experience on Linux Debian/Ubuntu and macOS.

## One-liner bootstrap

```bash
curl -fsSL https://raw.githubusercontent.com/biendo27/os-setup/main/bin/raw-bootstrap.sh | bash
```

You can pin repo/ref with env vars:

```bash
OSSETUP_REPO_URL="https://github.com/biendo27/os-setup.git" \
OSSETUP_REPO_REF="main" \
curl -fsSL https://raw.githubusercontent.com/biendo27/os-setup/main/bin/raw-bootstrap.sh | bash
```

## Local usage

```bash
./bin/ossetup help
./bin/ossetup doctor
./bin/ossetup install --profile default --target auto --host auto
./bin/ossetup sync --preview
./bin/ossetup sync --apply
./bin/ossetup sync-all --apply --target auto --scope all
./bin/ossetup promote --target auto --scope all --from-state latest --preview
./bin/ossetup promote --target auto --scope all --from-state latest --apply
./bin/ossetup update-globals
./bin/ossetup verify --report
./bin/ossetup verify --strict --report
./bin/ossetup doctor --require-global
./bin/migrate-npm-globals-to-mise.sh
```

## Documentation Index

- Architecture: [`docs/architecture/ARCHITECTURE.md`](docs/architecture/ARCHITECTURE.md)
- Invariants: [`docs/architecture/INVARIANTS.md`](docs/architecture/INVARIANTS.md)
- Data contracts: [`docs/architecture/DATA-CONTRACTS.md`](docs/architecture/DATA-CONTRACTS.md)
- Agent handoff context: [`docs/agents/AGENT_CONTEXT.md`](docs/agents/AGENT_CONTEXT.md)
- Cleanup inventory: [`docs/cleanup/cleanup-inventory.md`](docs/cleanup/cleanup-inventory.md)
- Deprecations log: [`docs/deprecations.md`](docs/deprecations.md)
- Migration notes: [`docs/migration-notes.md`](docs/migration-notes.md)
- Runbooks:
  - [`docs/runbooks/DEBUGGING.md`](docs/runbooks/DEBUGGING.md)
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
- Git workflow policy (trunk-based, PR-only, merge-commit) is in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Commands

- `bootstrap`: delegates to `install`
- `install`: installs packages, dotfiles, functions, mise, Android SDK, npm globals, and Bitwarden checks
  - `--host <id|auto>` resolves host overlay (`auto` uses normalized hostname)
- `sync`: syncs local HOME config back into repo (`--preview` by default)
- `sync-all`: runs `sync` and/or refreshes software manifests from the current machine
  - `--scope config|state|all` (default `all`)
- `promote`: promotes captured `manifests/state/<target>/*` snapshots into `manifests/layers/targets/<target>.yaml`
  - `--preview` shows plan only, `--apply` writes manifests
- `update-globals`: updates global packages managed by `npm`, `pnpm`, `yarn`, `pipx`, and `dart pub global`
  - Supports `--dry-run` to preview commands without executing
  - Interactive confirmation `[Y/n]` (default Yes), use `-y`/`--yes` to skip prompts
- `verify`: validates current machine state against repo and writes report in `reports/<timestamp>/verify-report.txt`
  - `--strict` also enforces state/manifest drift checks
- `doctor`: validates manifests and local prerequisites
  - `--require-global` also verifies global `ossetup` shim at `~/.local/bin/ossetup`
- `bin/migrate-npm-globals-to-mise.sh`: imports all current `npm -g` packages into the `mise npm:` backend and runs `mise reshim`

## Update Strategy

`functions/update-all` now follows a mise-first workflow for developer tools:

1. System updates: `apt` (if available) and `snap`
2. Toolchain updates: `mise upgrade --yes`
3. Shim refresh: `mise reshim`

It intentionally does **not** run `npm update -g` anymore.

If you use zsh functions from this repo, `functions/update-globals` is also provided and delegates to:

```bash
ossetup update-globals
```

Manifest files use JSON-compatible YAML syntax and currently live under:

- `manifests/profiles/*.yaml`
- `manifests/targets/*.yaml` (legacy compatibility path)
- `manifests/layers/core.yaml`
- `manifests/layers/targets/*.yaml`
- `manifests/layers/hosts/*.yaml`

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

Managed via `manifests/dotfiles.yaml` and backed up before overwrite:

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

## Controlled Cleanup

Cleanup is tracked in [`docs/cleanup/cleanup-inventory.md`](docs/cleanup/cleanup-inventory.md) with three classes:

- `remove-now`: safe to remove immediately (unreferenced, replaced, covered by tests)
- `archive-first`: historical or compatibility-sensitive; archive first when still needed for context
- `keep`: still part of supported architecture

For deprecation timelines and migration mapping, use:

- [`docs/deprecations.md`](docs/deprecations.md)
- [`docs/migration-notes.md`](docs/migration-notes.md)

## Removed legacy shims

The following wrappers were removed after deprecation window review:

- `bin/setup.sh` -> use `bin/ossetup install`
- `bin/sync-from-home.sh` -> use `bin/ossetup sync --apply`
- `bin/setup-zsh-functions.sh` -> use `bin/ossetup install`

## Testing

```bash
bats tests
for f in $(rg --files -g '*.sh' bin lib hooks popos-migration/scripts tests) bin/ossetup; do bash -n "$f"; done
for f in manifests/*.yaml manifests/profiles/*.yaml manifests/targets/*.yaml manifests/layers/core.yaml manifests/layers/targets/*.yaml; do jq -e . "$f" >/dev/null; done
```

## License

This project is licensed under the MIT License. See [`LICENSE`](LICENSE).
