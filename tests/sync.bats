#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true
  export OSSETUP_HOME_DIR="$BATS_TEST_TMPDIR/home"
  mkdir -p "$OSSETUP_HOME_DIR/.config"
  cp "$work/dotfiles/.zshrc" "$OSSETUP_HOME_DIR/.zshrc"
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

  grep -q "# synced-by-all" "$work/dotfiles/.zshrc"
  [[ "$(jq -r '.packages.apt[]' "$work/manifests/targets/linux-debian.yaml")" == *"my-new-cli"* ]]
  [[ "$(jq -r '.packages.flatpak[]' "$work/manifests/targets/linux-debian.yaml")" == *"org.telegram.desktop"* ]]
  [[ "$(jq -r '.packages.snap[]' "$work/manifests/targets/linux-debian.yaml")" == *"discord"* ]]
  [[ "$(jq -r '.npm_globals[]' "$work/manifests/targets/linux-debian.yaml")" == *"my-npm-tool"* ]]
}
