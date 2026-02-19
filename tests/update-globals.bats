#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true

  fakebin="$BATS_TEST_TMPDIR/fakebin"
  log="$BATS_TEST_TMPDIR/update-globals.log"
  mkdir -p "$fakebin"

  mkfake() {
    local name="$1"
    cat > "$fakebin/$name" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "$(basename "$0")" "$*" >> "__LOG__"
EOS
    sed -i "s#__LOG__#$log#g" "$fakebin/$name"
    chmod +x "$fakebin/$name"
  }

  mkfake npm
  mkfake pnpm
  mkfake pipx

  cat > "$fakebin/yarn" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "yarn" "$*" >> "__LOG__"
if [[ "${1:-}" == "--version" ]]; then
  echo "${YARN_VERSION:-1.22.22}"
fi
EOS
  sed -i "s#__LOG__#$log#g" "$fakebin/yarn"
  chmod +x "$fakebin/yarn"

  cat > "$fakebin/dart" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "dart" "$*" >> "__LOG__"

case "$*" in
  "pub global list")
    if [[ "${DART_GLOBAL_MODE:-with-packages}" == "with-packages" ]]; then
      cat <<PKG
melos 6.3.3
shorebird_cli 1.0.0
PKG
    fi
    ;;
  "pub global activate "*)
    ;;
esac
EOS
  sed -i "s#__LOG__#$log#g" "$fakebin/dart"
  chmod +x "$fakebin/dart"
}

@test "ossetup update-globals -y updates managers and skips yarn berry global command" {
  run env PATH="$fakebin:$PATH" YARN_VERSION=4.0.0 "$work/bin/ossetup" update-globals -y
  [ "$status" -eq 0 ]

  grep -q '^npm update -g$' "$log"
  grep -q '^pnpm update -g --latest$' "$log"
  grep -q '^yarn --version$' "$log"
  ! grep -q '^yarn global upgrade$' "$log"
  grep -q '^pipx upgrade-all$' "$log"
  grep -q '^dart pub global list$' "$log"
  grep -q '^dart pub global activate melos$' "$log"
  grep -q '^dart pub global activate shorebird_cli$' "$log"
}

@test "ossetup update-globals returns non-zero when no supported managers are available" {
  rm -rf "$fakebin"
  mkdir -p "$fakebin"

  run env PATH="$fakebin:/usr/bin:/bin" "$work/bin/ossetup" update-globals
  [ "$status" -eq 1 ]
  [[ "$output" == *"no supported global package managers found"* ]]
}

@test "ossetup update-globals rejects unknown options" {
  run env PATH="$fakebin:$PATH" "$work/bin/ossetup" update-globals --unknown
  [ "$status" -eq 64 ]
  [[ "$output" == *"unknown update-globals option: --unknown"* ]]
}

@test "ossetup update-globals uses yarn global upgrade on yarn classic" {
  run env PATH="$fakebin:$PATH" YARN_VERSION=1.22.22 "$work/bin/ossetup" update-globals -y
  [ "$status" -eq 0 ]
  grep -q '^yarn --version$' "$log"
  grep -q '^yarn global upgrade$' "$log"
}

@test "ossetup update-globals defaults to yes in non-interactive mode" {
  run env PATH="$fakebin:$PATH" YARN_VERSION=1.22.22 "$work/bin/ossetup" update-globals
  [ "$status" -eq 0 ]
  [[ "$output" == *"non-interactive stdin; default yes for: Update npm global packages?"* ]]
  grep -q '^npm update -g$' "$log"
  grep -q '^pnpm update -g --latest$' "$log"
  grep -q '^yarn global upgrade$' "$log"
}
