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
./bin/ossetup install --profile default --target auto
./bin/ossetup sync --preview
./bin/ossetup sync --apply
./bin/ossetup sync-all --apply --target auto
./bin/ossetup update-globals
./bin/ossetup verify --report
./bin/ossetup doctor --require-global
./bin/migrate-npm-globals-to-mise.sh
```

## Commands

- `bootstrap`: delegates to `install`
- `install`: installs packages, dotfiles, functions, mise, Android SDK, npm globals, and Bitwarden checks
- `sync`: syncs local HOME config back into repo (`--preview` by default)
- `sync-all`: runs `sync` and also refreshes software manifests from the current machine
- `update-globals`: updates global packages managed by `npm`, `pnpm`, `yarn`, `pipx`, and `dart pub global`
  - Supports `--dry-run` to preview commands without executing
  - Interactive confirmation `[Y/n]` (default Yes), use `-y`/`--yes` to skip prompts
- `verify`: validates current machine state against repo and writes report in `reports/<timestamp>/verify-report.txt`
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

Manifest files live under `manifests/*.yaml` and currently use JSON-compatible YAML syntax so they can be parsed with `jq`.

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
- `functions/*` <-> `~/.config/zsh/functions/*`

## Testing

```bash
bats tests
```
