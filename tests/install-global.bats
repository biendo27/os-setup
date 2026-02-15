#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true
  export OSSETUP_HOME_DIR="$BATS_TEST_TMPDIR/home"
  mkdir -p "$OSSETUP_HOME_DIR"

  cat > "$work/manifests/profiles/test-global.yaml" <<'JSON'
{
  "name": "test-global",
  "modules": {
    "global_cli": true
  }
}
JSON
}

@test "install creates global ossetup shim" {
  run "$work/bin/ossetup" install --profile test-global --target linux-debian
  [ "$status" -eq 0 ]

  shim="$OSSETUP_HOME_DIR/.local/bin/ossetup"
  [ -x "$shim" ]
  grep -Fq "exec \"$work/bin/ossetup\" \"\$@\"" "$shim"
  grep -Fq '# >>> ossetup path >>>' "$OSSETUP_HOME_DIR/.zshrc"
}

@test "install is idempotent for zshrc PATH block" {
  run "$work/bin/ossetup" install --profile test-global --target linux-debian
  [ "$status" -eq 0 ]

  run "$work/bin/ossetup" install --profile test-global --target linux-debian
  [ "$status" -eq 0 ]

  count="$(grep -c '# >>> ossetup path >>>' "$OSSETUP_HOME_DIR/.zshrc")"
  [ "$count" -eq 1 ]
}
