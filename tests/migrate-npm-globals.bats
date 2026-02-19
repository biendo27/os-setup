#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"

  fakebin="$BATS_TEST_TMPDIR/fakebin"
  log="$BATS_TEST_TMPDIR/migrate.log"
  mkdir -p "$fakebin"

  inject_log() {
    local script="$1"
    perl -0pi -e 's#__LOG__#'"$log"'#g' "$script"
  }

  cat > "$fakebin/npm" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "ls" && "${2:-}" == "-g" && "${3:-}" == "--depth=0" && "${4:-}" == "--json" ]]; then
  printf '{"dependencies":{"@openai/codex":{},"wrangler":{},"repomix":{}}}\n'
  exit 0
fi
exit 1
EOS
  chmod +x "$fakebin/npm"

  cat > "$fakebin/mise" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "__LOG__"
exit 0
EOS
  inject_log "$fakebin/mise"
  chmod +x "$fakebin/mise"

  cat > "$fakebin/jq" <<'EOS'
#!/usr/bin/env bash
exec /usr/bin/jq "$@"
EOS
  chmod +x "$fakebin/jq"
}

@test "migrate script imports npm globals into mise npm backend and reshim" {
  run env PATH="$fakebin:$PATH" "$work/bin/migrate-npm-globals-to-mise.sh"
  [ "$status" -eq 0 ]

  grep -q '^use -g npm:@openai/codex@latest$' "$log"
  grep -q '^use -g npm:repomix@latest$' "$log"
  grep -q '^use -g npm:wrangler@latest$' "$log"
  grep -q '^reshim$' "$log"
}
