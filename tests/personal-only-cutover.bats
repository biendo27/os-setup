#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/helpers/workspace-fixture.bash"

setup() {
  core="$BATS_TEST_TMPDIR/core"
  personal="$BATS_TEST_TMPDIR/personal"
  cp -R "$BATS_TEST_DIRNAME/.." "$core"
  mkdir -p "$personal"
  chmod +x "$core/bin/ossetup" 2>/dev/null || true

  export OSSETUP_HOME_DIR="$BATS_TEST_TMPDIR/home"
  mkdir -p "$OSSETUP_HOME_DIR/.config" "$OSSETUP_HOME_DIR/.ssh" "$OSSETUP_HOME_DIR/.config/zsh/functions"

  # Seed minimal personal runtime data from repository snapshot.
  seed_personal_data_from_repo "$core" "$personal"

  cp "$personal/dotfiles/.zshrc" "$OSSETUP_HOME_DIR/.zshrc"

  cat > "$personal/.ossetup-workspace.json" <<'JSON'
{
  "schema_version": 1,
  "core_repo_url": "https://github.com/biendo27/os-setup.git",
  "core_repo_ref": "main",
  "core_repo_path": "../core",
  "user_id": "emanon",
  "mode": "personal-only"
}
JSON
}

@test "doctor fails fast when workspace config is missing" {
  run "$core/bin/ossetup" doctor
  [ "$status" -eq 65 ]
  [[ "$output" == *"workspace config is required"* ]]
}

@test "install executes personal hooks only" {
  export OSSETUP_WORKSPACE_FILE="$personal/.ossetup-workspace.json"
  rm -rf "$core/hooks"

  mkdir -p "$personal/hooks/pre-install.d" "$personal/hooks/post-install.d"
  cat > "$personal/hooks/pre-install.d/00-test-pre.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'personal-pre\n'
SH
  chmod +x "$personal/hooks/pre-install.d/00-test-pre.sh"

  cat > "$personal/hooks/post-install.d/90-test-post.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'personal-post\n'
SH
  chmod +x "$personal/hooks/post-install.d/90-test-post.sh"

  run bash -lc "cd '$personal' && '$core/bin/ossetup' install --dry-run --target linux-debian --profile default"
  [ "$status" -eq 0 ]
  [[ "$output" == *"personal-pre"* ]]
  [[ "$output" == *"personal-post"* ]]
}

@test "promote apply is enabled in personal-only mode and mutates personal target layer" {
  export OSSETUP_WORKSPACE_FILE="$personal/.ossetup-workspace.json"

  mkdir -p "$personal/manifests/layers/targets" "$personal/manifests/state/linux-debian"
  cat > "$personal/manifests/layers/targets/linux-debian.yaml" <<'JSON'
{
  "packages": {
    "apt": ["old-apt"],
    "flatpak": ["old-flatpak"],
    "snap": ["old-snap"]
  },
  "npm_globals": ["old-npm"]
}
JSON

  cat > "$personal/manifests/state/linux-debian/apt-manual.txt" <<'TXT'
curl
git
TXT
  cat > "$personal/manifests/state/linux-debian/flatpak-apps.txt" <<'TXT'
org.example.NewFlatpak
TXT
  cat > "$personal/manifests/state/linux-debian/snap-list.txt" <<'TXT'
new-snap
TXT
  cat > "$personal/manifests/state/linux-debian/npm-globals.txt" <<'TXT'
@openai/codex
TXT

  run bash -lc "cd '$personal' && '$core/bin/ossetup' promote --target linux-debian --scope all --from-state latest --apply"
  [ "$status" -eq 0 ]
  [[ "$output" == *"PROMOTE APPLY"* ]]

  run jq -r '.packages.apt[]' "$personal/manifests/layers/targets/linux-debian.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == $'curl\ngit' ]]
}

@test "legacy workspace mode personal-overrides is accepted as alias" {
  cat > "$personal/.ossetup-workspace.json" <<'JSON'
{
  "schema_version": 1,
  "core_repo_url": "https://github.com/biendo27/os-setup.git",
  "core_repo_ref": "main",
  "core_repo_path": "../core",
  "user_id": "emanon",
  "mode": "personal-overrides"
}
JSON

  export OSSETUP_WORKSPACE_FILE="$personal/.ossetup-workspace.json"
  run bash -lc "cd '$personal' && '$core/bin/ossetup' doctor"
  [ "$status" -eq 0 ]
  [[ "$output" == *"workspace mode: personal-only"* ]]
}
