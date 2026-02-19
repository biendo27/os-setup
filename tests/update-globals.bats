#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true

  fakebin="$BATS_TEST_TMPDIR/fakebin"
  log="$BATS_TEST_TMPDIR/update-globals.log"
  mkdir -p "$fakebin"

  cat > "$fakebin/mise" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "mise" "$*" >> "__LOG__"
case "${1:-}" in
  ls)
    echo '{}'
    ;;
  upgrade|reshim)
    ;;
esac
EOS
  sed -i "s#__LOG__#$log#g" "$fakebin/mise"
  chmod +x "$fakebin/mise"

  cat > "$fakebin/jq" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "jq" "$*" >> "__LOG__"
case "${MISE_BACKEND_MODE:-with-backends}" in
  with-backends)
    printf '%s\n' "cargo:eza" "npm:@openai/codex"
    ;;
  no-backends)
    ;;
esac
EOS
  sed -i "s#__LOG__#$log#g" "$fakebin/jq"
  chmod +x "$fakebin/jq"
}

@test "ossetup update-globals upgrades only mise backend global tools and reshim" {
  run env PATH="$fakebin:$PATH" "$work/bin/ossetup" update-globals
  [ "$status" -eq 0 ]

  grep -q '^mise ls --global --current --json$' "$log"
  grep -q '^jq -r keys\[\] | select(test(":"))$' "$log"
  grep -q '^mise upgrade --yes cargo:eza npm:@openai/codex$' "$log"
  grep -q '^mise reshim$' "$log"
}

@test "ossetup update-globals exits cleanly when no backend global tools are configured" {
  run env PATH="$fakebin:$PATH" MISE_BACKEND_MODE=no-backends "$work/bin/ossetup" update-globals
  [ "$status" -eq 0 ]
  [[ "$output" == *"no mise backend tools configured globally"* ]]

  grep -q '^mise ls --global --current --json$' "$log"
  grep -q '^jq -r keys\[\] | select(test(":"))$' "$log"
  ! grep -q '^mise upgrade --yes' "$log"
  ! grep -q '^mise reshim$' "$log"
}
