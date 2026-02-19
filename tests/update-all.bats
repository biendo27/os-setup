#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/functions/update-all" 2>/dev/null || true

  fakebin="$BATS_TEST_TMPDIR/fakebin"
  log="$BATS_TEST_TMPDIR/update-all.log"
  mkdir -p "$fakebin"

  mkfake() {
    local name="$1"
    cat > "$fakebin/$name" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "$(basename "$0")" "$*" >> "__LOG__"
exit 0
EOS
    sed -i "s#__LOG__#$log#g" "$fakebin/$name"
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
  sed -i "s#__LOG__#$log#g" "$fakebin/sudo"
  chmod +x "$fakebin/sudo"

  cat > "$fakebin/dpkg" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "dpkg" "$*" >> "__LOG__"
if [[ "${1:-}" == "--print-architecture" ]]; then
  echo amd64
fi
EOS
  sed -i "s#__LOG__#$log#g" "$fakebin/dpkg"
  chmod +x "$fakebin/dpkg"

  cat > "$fakebin/dpkg-query" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "dpkg-query" "$*" >> "__LOG__"
exit 1
EOS
  sed -i "s#__LOG__#$log#g" "$fakebin/dpkg-query"
  chmod +x "$fakebin/dpkg-query"
}

@test "update-all uses apt/snap + mise upgrade/reshim and skips npm update -g" {
  run env PATH="$fakebin:$PATH" WORK_DIR="$work" zsh -lc 'source "$WORK_DIR/functions/update-all"; update-all'
  [ "$status" -eq 0 ]

  grep -q '^sudo -v$' "$log"
  grep -q '^sudo apt update$' "$log"
  grep -q '^sudo apt upgrade -y$' "$log"
  grep -q '^sudo snap refresh$' "$log"
  grep -q '^mise upgrade --yes$' "$log"
  grep -q '^mise reshim$' "$log"
  ! grep -q '^npm update -g$' "$log"
}
