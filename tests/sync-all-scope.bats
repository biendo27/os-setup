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
  local layered="$work/manifests/layers/targets/linux-debian.yaml"
  if [[ -f "$layered" ]]; then
    printf '%s\n' "$layered"
    return 0
  fi
  printf '%s\n' "$work/manifests/targets/linux-debian.yaml"
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

@test "sync-all --scope config applies sync only" {
  printf '\n# config-only\n' >> "$OSSETUP_HOME_DIR/.zshrc"

  local target_manifest
  target_manifest="$(target_manifest_for_state)"
  before_manifest="$(sha256sum "$target_manifest" | awk '{print $1}')"

  run "$work/bin/ossetup" sync-all --apply --target linux-debian --scope config
  [ "$status" -eq 0 ]
  [[ "$output" == *"scope=config"* ]]

  grep -q '# config-only' "$work/dotfiles/.zshrc"

  after_manifest="$(sha256sum "$target_manifest" | awk '{print $1}')"
  [ "$before_manifest" = "$after_manifest" ]
}

@test "sync-all --scope state exports state only" {
  printf '\n# state-only-should-not-sync\n' >> "$OSSETUP_HOME_DIR/.zshrc"
  write_fake_state_tools

  before_dotfile="$(sha256sum "$work/dotfiles/.zshrc" | awk '{print $1}')"

  PATH="$fakebin:$PATH" run "$work/bin/ossetup" sync-all --apply --target linux-debian --scope state
  [ "$status" -eq 0 ]
  [[ "$output" == *"scope=state"* ]]

  after_dotfile="$(sha256sum "$work/dotfiles/.zshrc" | awk '{print $1}')"
  [ "$before_dotfile" = "$after_dotfile" ]

  local target_manifest
  target_manifest="$(target_manifest_for_state)"
  [ "$(jq -r '.packages.apt[] | select(. == "state-only-cli")' "$target_manifest")" = "state-only-cli" ]
  [ "$(jq -r '.npm_globals[] | select(. == "state-npm-cli")' "$target_manifest")" = "state-npm-cli" ]
}

@test "sync-all rejects invalid scope value" {
  run "$work/bin/ossetup" sync-all --preview --target linux-debian --scope invalid
  [ "$status" -eq 64 ]
  [[ "$output" == *"invalid scope"* ]]
}
