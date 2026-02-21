# Personal Workspace Runbook

## Goal

Run OSSetup with a shared core repo and a personal overrides repo, while keeping one-command bootstrap for new machines.

## Layout

- Core repo: `../OSSetup`
- Personal repo (example): `../emanon-ossync`

## Create Personal Repo

1. Create and clone your personal repo.
2. Add workspace config at personal repo root:

```json
{
  "schema_version": 1,
  "core_repo_url": "https://github.com/biendo27/os-setup.git",
  "core_repo_ref": "main",
  "core_repo_path": "../OSSetup",
  "user_id": "emanon",
  "mode": "personal-overrides"
}
```

## Daily Workflow

Run commands from the personal repo directory.

```bash
ossetup sync --preview
ossetup sync --apply
ossetup sync-all --apply --target auto --scope state
ossetup install --profile default --target auto --host auto
ossetup verify --strict --report
```

Behavior in personal mode:

- `sync --apply` writes only personal files.
- `sync-all --scope state --apply` writes personal state and personal user layer.
- `promote --apply` is blocked (preview-only).

## New Machine Bootstrap (One-Liner)

Host this script as `bin/raw-bootstrap.sh` in the personal repo and use it for `curl | bash`:

```bash
#!/usr/bin/env bash
set -euo pipefail

PERSONAL_REPO_URL="${OSSETUP_PERSONAL_REPO_URL:-https://github.com/<your-user>/emanon-ossync.git}"
PERSONAL_REPO_REF="${OSSETUP_PERSONAL_REPO_REF:-main}"
PERSONAL_DIR="${OSSETUP_PERSONAL_DIR:-$HOME/.local/share/emanon-ossync}"

mkdir -p "$(dirname "$PERSONAL_DIR")"

if [[ -d "$PERSONAL_DIR/.git" ]]; then
  git -C "$PERSONAL_DIR" fetch --depth 1 origin "$PERSONAL_REPO_REF"
  git -C "$PERSONAL_DIR" checkout -f FETCH_HEAD
else
  git clone --depth 1 --branch "$PERSONAL_REPO_REF" "$PERSONAL_REPO_URL" "$PERSONAL_DIR"
fi

workspace="$PERSONAL_DIR/.ossetup-workspace.json"
core_url="$(jq -r '.core_repo_url // empty' "$workspace")"
core_ref="$(jq -r '.core_repo_ref // "main"' "$workspace")"
core_rel="$(jq -r '.core_repo_path' "$workspace")"
core_dir="$PERSONAL_DIR/$core_rel"

mkdir -p "$(dirname "$core_dir")"
if [[ -d "$core_dir/.git" ]]; then
  git -C "$core_dir" fetch --depth 1 origin "$core_ref"
  git -C "$core_dir" checkout -f FETCH_HEAD
else
  git clone --depth 1 --branch "$core_ref" "$core_url" "$core_dir"
fi

cd "$PERSONAL_DIR"
exec "$core_dir/bin/ossetup" install --profile default --target auto --host auto
```

