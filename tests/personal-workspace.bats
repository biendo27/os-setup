#!/usr/bin/env bats

setup() {
  core="$BATS_TEST_TMPDIR/core"
  personal="$BATS_TEST_TMPDIR/personal"
  cp -R "$BATS_TEST_DIRNAME/.." "$core"
  mkdir -p "$personal"
  chmod +x "$core/bin/ossetup" 2>/dev/null || true

  export OSSETUP_HOME_DIR="$BATS_TEST_TMPDIR/home"
  mkdir -p "$OSSETUP_HOME_DIR/.config"
  cp "$core/dotfiles/.zshrc" "$OSSETUP_HOME_DIR/.zshrc"

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
}

write_fake_state_tools() {
  fakebin="$BATS_TEST_TMPDIR/fakebin"
  mkdir -p "$fakebin"

  cat > "$fakebin/apt-mark" <<'EOS'
#!/usr/bin/env bash
if [[ "${1:-}" == "showmanual" ]]; then
  printf 'curl\ngit\nstate-only-cli\n'
  exit 0
fi
exit 1
EOS

  cat > "$fakebin/flatpak" <<'EOS'
#!/usr/bin/env bash
if [[ "${1:-}" == "list" ]]; then
  printf 'org.example.StateFlatpak\n'
  exit 0
fi
exit 1
EOS

  cat > "$fakebin/snap" <<'EOS'
#!/usr/bin/env bash
if [[ "${1:-}" == "list" ]]; then
  printf 'Name Version Rev Tracking Publisher Notes\n'
  printf 'state-snap 1 1 latest/stable canonical -\n'
  exit 0
fi
exit 1
EOS

  cat > "$fakebin/npm" <<'EOS'
#!/usr/bin/env bash
if [[ "${1:-}" == "list" && "${2:-}" == "-g" ]]; then
  printf '{"dependencies":{"state-npm-cli":{}}}\n'
  exit 0
fi
exit 1
EOS

  chmod +x "$fakebin/apt-mark" "$fakebin/flatpak" "$fakebin/snap" "$fakebin/npm"
}

@test "sync apply writes personal repo and does not mutate core repo" {
  printf '\n# personal-sync\n' >> "$OSSETUP_HOME_DIR/.zshrc"
  before_core="$(sha256sum "$core/dotfiles/.zshrc" | awk '{print $1}')"

  run bash -lc "cd '$personal' && '$core/bin/ossetup' sync --apply"
  [ "$status" -eq 0 ]

  [ -f "$personal/dotfiles/.zshrc" ]
  grep -q '# personal-sync' "$personal/dotfiles/.zshrc"

  after_core="$(sha256sum "$core/dotfiles/.zshrc" | awk '{print $1}')"
  [ "$before_core" = "$after_core" ]
}

@test "sync apply fails when run from core repo in personal mode" {
  printf '\n# should-not-write-core\n' >> "$OSSETUP_HOME_DIR/.zshrc"

  run bash -lc "cd '$core' && '$core/bin/ossetup' sync --apply"
  [ "$status" -eq 65 ]
  [[ "$output" == *"personal repo"* ]]
}

@test "sync-all --scope state writes state into personal repo only" {
  write_fake_state_tools
  before_core_manifest="$(sha256sum "$core/manifests/layers/targets/linux-debian.yaml" | awk '{print $1}')"

  run bash -lc "cd '$personal' && PATH='$fakebin':\"\$PATH\" '$core/bin/ossetup' sync-all --apply --target linux-debian --scope state"
  [ "$status" -eq 0 ]

  [ -f "$personal/manifests/state/linux-debian/apt-manual.txt" ]
  grep -q '^state-only-cli$' "$personal/manifests/state/linux-debian/apt-manual.txt"

  after_core_manifest="$(sha256sum "$core/manifests/layers/targets/linux-debian.yaml" | awk '{print $1}')"
  [ "$before_core_manifest" = "$after_core_manifest" ]
}

@test "install prefers personal dotfile override over core" {
  cat > "$core/manifests/profiles/personal-test.yaml" <<'JSON'
{
  "name": "personal-test",
  "modules": {
    "packages": false,
    "dotfiles": true,
    "functions": false,
    "mise": false,
    "android_sdk": false,
    "npm_globals": false,
    "secrets": false,
    "global_cli": false
  }
}
JSON

  printf 'core-version\n' > "$core/dotfiles/.zshrc"
  mkdir -p "$personal/dotfiles"
  printf 'personal-version\n' > "$personal/dotfiles/.zshrc"

  run bash -lc "cd '$personal' && '$core/bin/ossetup' install --profile personal-test --target linux-debian --host auto"
  [ "$status" -eq 0 ]
  grep -q '^personal-version$' "$OSSETUP_HOME_DIR/.zshrc"
}

@test "promote apply is blocked in personal mode" {
  mkdir -p "$personal/manifests/state/linux-debian"
  printf 'curl\ngit\n' > "$personal/manifests/state/linux-debian/apt-manual.txt"
  : > "$personal/manifests/state/linux-debian/flatpak-apps.txt"
  : > "$personal/manifests/state/linux-debian/snap-list.txt"
  : > "$personal/manifests/state/linux-debian/npm-globals.txt"

  run bash -lc "cd '$personal' && '$core/bin/ossetup' promote --apply --target linux-debian"
  [ "$status" -eq 64 ]
  [[ "$output" == *"preview-only"* ]]
}

@test "workspace config is auto-discovered from current directory" {
  unset OSSETUP_WORKSPACE_FILE

  run bash -lc "cd '$personal' && '$core/bin/ossetup' doctor"
  [ "$status" -eq 0 ]
  [[ "$output" == *"workspace mode: personal-overrides"* ]]
}

@test "sync apply guard works when core path uses symlink alias" {
  local core_link="$BATS_TEST_TMPDIR/core-link"
  ln -s "$core" "$core_link"

  cat > "$personal/.ossetup-workspace.json" <<'JSON'
{
  "schema_version": 1,
  "core_repo_url": "https://github.com/biendo27/os-setup.git",
  "core_repo_ref": "main",
  "core_repo_path": "../core-link",
  "user_id": "emanon",
  "mode": "personal-overrides"
}
JSON

  run bash -lc "cd '$core' && OSSETUP_WORKSPACE_FILE='$personal/.ossetup-workspace.json' '$core/bin/ossetup' sync --apply"
  [ "$status" -eq 65 ]
  [[ "$output" == *"personal repo"* ]]
}
