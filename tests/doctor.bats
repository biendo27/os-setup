#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/helpers/workspace-fixture.bash"

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true
  setup_workspace_in_repo "$work"
  export OSSETUP_HOME_DIR="$BATS_TEST_TMPDIR/home"
  mkdir -p "$OSSETUP_HOME_DIR"
}

@test "doctor --require-global fails when shim is missing" {
  run "$work/bin/ossetup" doctor --require-global
  [ "$status" -eq 65 ]
  [[ "$output" == *"global ossetup shim missing"* ]]
}

@test "doctor --require-global passes when shim exists and is in PATH" {
  mkdir -p "$OSSETUP_HOME_DIR/.local/bin"
  cat > "$OSSETUP_HOME_DIR/.local/bin/ossetup" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "$work/bin/ossetup" "\$@"
EOF
  chmod +x "$OSSETUP_HOME_DIR/.local/bin/ossetup"

  PATH="$OSSETUP_HOME_DIR/.local/bin:$PATH" run "$work/bin/ossetup" doctor --require-global
  [ "$status" -eq 0 ]
  [[ "$output" == *"global shim ok"* ]]
}
