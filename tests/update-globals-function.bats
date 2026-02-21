#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/helpers/workspace-fixture.bash"

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  seed_personal_runtime_templates "$work" "$work"

  fakebin="$BATS_TEST_TMPDIR/fakebin"
  log="$BATS_TEST_TMPDIR/update-globals-function.log"
  mkdir -p "$fakebin"

  inject_log() {
    local script="$1"
    perl -0pi -e 's#__LOG__#'"$log"'#g' "$script"
  }

  cat > "$fakebin/ossetup" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "ossetup" "$*" >> "__LOG__"
EOS
  inject_log "$fakebin/ossetup"
  chmod +x "$fakebin/ossetup"
}

@test "update-globals function delegates to ossetup command" {
  run env PATH="$fakebin:/usr/bin:/bin" WORK_DIR="$work" zsh -f -c 'source "$WORK_DIR/functions/update-globals"; update-globals --dry-run'
  [ "$status" -eq 0 ]
  grep -q '^ossetup update-globals --dry-run$' "$log"
}
