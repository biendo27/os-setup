#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true
  export OSSETUP_HOME_DIR="$BATS_TEST_TMPDIR/home"
  mkdir -p "$OSSETUP_HOME_DIR/.config"
  cp "$work/dotfiles/.zshrc" "$OSSETUP_HOME_DIR/.zshrc"
}

target_manifest_for_state() {
  local target="$1"
  local layered="$work/manifests/layers/targets/$target.yaml"
  if [[ -f "$layered" ]]; then
    printf '%s\n' "$layered"
    return 0
  fi
  printf '%s\n' "$work/manifests/targets/$target.yaml"
}

@test "sync preview does not mutate repo files" {
  echo "# local change" >> "$OSSETUP_HOME_DIR/.zshrc"
  before="$(sha256sum "$work/dotfiles/.zshrc" | awk '{print $1}')"

  run "$work/bin/ossetup" sync --preview
  [ "$status" -eq 0 ]
  [[ "$output" == *"PREVIEW"* ]]
  [[ "$output" == *"CHANGED"* ]]

  after="$(sha256sum "$work/dotfiles/.zshrc" | awk '{print $1}')"
  [ "$before" = "$after" ]
}

@test "sync apply copies local dotfile into repo" {
  printf '\n# synced\n' >> "$OSSETUP_HOME_DIR/.zshrc"

  run "$work/bin/ossetup" sync --apply
  [ "$status" -eq 0 ]
  [[ "$output" == *"APPLY"* ]]

  grep -q "# synced" "$work/dotfiles/.zshrc"
}

@test "sync-all apply updates package manifests from current machine" {
  printf '\n# synced-by-all\n' >> "$OSSETUP_HOME_DIR/.zshrc"

  fakebin="$BATS_TEST_TMPDIR/fakebin"
  mkdir -p "$fakebin"

  cat > "$fakebin/apt-mark" <<'EOS'
#!/usr/bin/env bash
if [[ "${1:-}" == "showmanual" ]]; then
  printf 'git\ncurl\nmy-new-cli\n'
  exit 0
fi
exit 1
EOS

  cat > "$fakebin/flatpak" <<'EOS'
#!/usr/bin/env bash
if [[ "${1:-}" == "list" ]]; then
  printf 'org.telegram.desktop\ncom.visualstudio.code\n'
  exit 0
fi
exit 1
EOS

  cat > "$fakebin/snap" <<'EOS'
#!/usr/bin/env bash
if [[ "${1:-}" == "list" ]]; then
  printf 'Name Version Rev Tracking Publisher Notes\n'
  printf 'discord 0.0.87 123 latest/stable canonical -\n'
  printf 'vlc 3.0.20 456 latest/stable canonical -\n'
  exit 0
fi
exit 1
EOS

  cat > "$fakebin/npm" <<'EOS'
#!/usr/bin/env bash
if [[ "${1:-}" == "list" && "${2:-}" == "-g" ]]; then
  printf '{"dependencies":{"@openai/codex":{},"my-npm-tool":{}}}\n'
  exit 0
fi
exit 1
EOS

  chmod +x "$fakebin/apt-mark" "$fakebin/flatpak" "$fakebin/snap" "$fakebin/npm"

  PATH="$fakebin:$PATH" run "$work/bin/ossetup" sync-all --apply --target linux-debian
  [ "$status" -eq 0 ]
  [[ "$output" == *"sync-all APPLY complete"* ]]

  local target_manifest
  target_manifest="$(target_manifest_for_state linux-debian)"

  grep -q "# synced-by-all" "$work/dotfiles/.zshrc"
  apt_len="$(jq '.packages.apt | length' "$target_manifest")"
  flatpak_len="$(jq '.packages.flatpak | length' "$target_manifest")"
  snap_len="$(jq '.packages.snap | length' "$target_manifest")"
  npm_len="$(jq '.npm_globals | length' "$target_manifest")"
  [ "$apt_len" -eq 3 ]
  [ "$flatpak_len" -eq 2 ]
  [ "$snap_len" -eq 2 ]
  [ "$npm_len" -eq 2 ]

  [ "$(jq -r '.packages.apt[2]' "$target_manifest")" = "my-new-cli" ]
  [ "$(jq -r '.packages.flatpak[0]' "$target_manifest")" = "com.visualstudio.code" ]
  [ "$(jq -r '.packages.snap[0]' "$target_manifest")" = "discord" ]
  [ "$(jq -r '.npm_globals[1]' "$target_manifest")" = "my-npm-tool" ]
}

@test "sync apply copies profile directory entries into repo" {
  cat > "$work/manifests/dotfiles.yaml" <<'JSON'
{
  "entries": [
    {
      "repo": "dotfiles/.config/Cursor/User/profiles",
      "home": "~/.config/Cursor/User/profiles",
      "type": "dir",
      "optional": true
    }
  ],
  "functions": {
    "repo_dir": "functions",
    "home_dir": "~/.config/zsh/functions"
  }
}
JSON

  mkdir -p "$OSSETUP_HOME_DIR/.config/Cursor/User/profiles/alpha"
  cat > "$OSSETUP_HOME_DIR/.config/Cursor/User/profiles/alpha/settings.json" <<'JSON'
{"editor.fontSize": 14}
JSON

  run "$work/bin/ossetup" sync --apply
  [ "$status" -eq 0 ]
  [[ "$output" == *"SYNCED ~/.config/Cursor/User/profiles -> dotfiles/.config/Cursor/User/profiles"* ]]
  [ -f "$work/dotfiles/.config/Cursor/User/profiles/alpha/settings.json" ]
}

@test "sync preview reports changed profile directory without mutating repo" {
  cat > "$work/manifests/dotfiles.yaml" <<'JSON'
{
  "entries": [
    {
      "repo": "dotfiles/.config/Antigravity/User/profiles",
      "home": "~/.config/Antigravity/User/profiles",
      "type": "dir",
      "optional": true
    }
  ],
  "functions": {
    "repo_dir": "functions",
    "home_dir": "~/.config/zsh/functions"
  }
}
JSON

  mkdir -p "$work/dotfiles/.config/Antigravity/User/profiles/default"
  printf 'repo-version\n' > "$work/dotfiles/.config/Antigravity/User/profiles/default/settings.json"

  mkdir -p "$OSSETUP_HOME_DIR/.config/Antigravity/User/profiles/default"
  printf 'home-version\n' > "$OSSETUP_HOME_DIR/.config/Antigravity/User/profiles/default/settings.json"

  before="$(sha256sum "$work/dotfiles/.config/Antigravity/User/profiles/default/settings.json" | awk '{print $1}')"

  run "$work/bin/ossetup" sync --preview
  [ "$status" -eq 0 ]
  [[ "$output" == *"CHANGED ~/.config/Antigravity/User/profiles -> dotfiles/.config/Antigravity/User/profiles"* ]]

  after="$(sha256sum "$work/dotfiles/.config/Antigravity/User/profiles/default/settings.json" | awk '{print $1}')"
  [ "$before" = "$after" ]
}
