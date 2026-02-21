#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/helpers/workspace-fixture.bash"

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  seed_personal_runtime_templates "$work" "$work"
  chmod +x "$work/functions/update-all" 2>/dev/null || true

  fakebin="$BATS_TEST_TMPDIR/fakebin"
  log="$BATS_TEST_TMPDIR/update-all.log"
  mkdir -p "$fakebin"

  inject_log() {
    local script="$1"
    perl -0pi -e 's#__LOG__#'"$log"'#g' "$script"
  }

  mkfake() {
    local name="$1"
    cat > "$fakebin/$name" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "$(basename "$0")" "$*" >> "__LOG__"
exit 0
EOS
    inject_log "$fakebin/$name"
    chmod +x "$fakebin/$name"
  }

  mkfake apt
  mkfake snap
  mkfake mise
  mkfake npm
  mkfake curl

  cat > "$fakebin/sudo" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "sudo" "$*" >> "__LOG__"
exit 0
EOS
  inject_log "$fakebin/sudo"
  chmod +x "$fakebin/sudo"

  cat > "$fakebin/dpkg" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "dpkg" "$*" >> "__LOG__"
if [[ "${1:-}" == "--print-architecture" ]]; then
  echo amd64
fi
EOS
  inject_log "$fakebin/dpkg"
  chmod +x "$fakebin/dpkg"

  cat > "$fakebin/dpkg-query" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "dpkg-query" "$*" >> "__LOG__"
exit 1
EOS
  inject_log "$fakebin/dpkg-query"
  chmod +x "$fakebin/dpkg-query"
}

@test "update-all uses apt/snap + mise upgrade/reshim and skips npm update -g" {
  run env PATH="$fakebin:/usr/bin:/bin" WORK_DIR="$work" zsh -f -c 'source "$WORK_DIR/functions/update-all"; update-all'
  [ "$status" -eq 0 ]

  if [[ "$(uname -s)" != "Darwin" ]]; then
    grep -q '^sudo -v$' "$log"
    grep -q '^sudo apt update$' "$log"
    grep -q '^sudo apt upgrade -y$' "$log"
    grep -q '^sudo snap refresh$' "$log"
  fi
  grep -q '^mise upgrade --yes$' "$log"
  grep -q '^mise reshim$' "$log"
  run grep -q '^npm update -g$' "$log"
  [ "$status" -eq 1 ]
}
