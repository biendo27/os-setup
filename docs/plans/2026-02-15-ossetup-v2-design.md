# OSSetup v2 Design

## Goal
Provide one-command bootstrap for Linux Debian/Ubuntu and macOS with reproducible tooling and dotfiles.

## Decisions
- Manifest-driven architecture.
- CLI entrypoint: `bin/ossetup`.
- Secrets via Bitwarden references only.
- Sync is preview-first (`--apply` required to mutate repo).
- Canonical zsh config: `dotfiles/.zshrc`, `dotfiles/.zimrc` with backup-and-replace policy.

## Implemented Structure
- `bin/ossetup` command router.
- `lib/core/*` shared runtime.
- `lib/runners/*` install/sync/verify/doctor/bootstrap.
- `lib/providers/*` package managers, dotfiles/functions, mise/npm, android sdk, bitwarden checks.
- `manifests/*` profile, targets, dotfiles, secrets.
- `hooks/pre-install.d` and `hooks/post-install.d`.

## Validation
- Bats tests cover CLI basics, install dry-run, sync preview/apply, and verify report generation.
