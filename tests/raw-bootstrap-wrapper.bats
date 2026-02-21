#!/usr/bin/env bats

create_personal_repo_fixture() {
  local repo_dir="$1"
  mkdir -p "$repo_dir/bin"

  cat > "$repo_dir/bin/raw-bootstrap.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'personal-bootstrap-ok\n'
SH
  chmod +x "$repo_dir/bin/raw-bootstrap.sh"

  git -C "$repo_dir" init -b main >/dev/null
  git -C "$repo_dir" config user.email "test@example.invalid"
  git -C "$repo_dir" config user.name "test"
  git -C "$repo_dir" add .
  git -C "$repo_dir" commit -m "init personal bootstrap fixture" >/dev/null
}

@test "core raw-bootstrap initializes personal workspace in core-first mode" {
  local core_src="$BATS_TEST_DIRNAME/.."
  local core_checkout="$BATS_TEST_TMPDIR/core-checkout"
  local personal_dir="$BATS_TEST_TMPDIR/personal-workspace"

  run env \
    OSSETUP_CORE_REPO_URL="file://$core_src" \
    OSSETUP_CORE_REPO_REF="main" \
    OSSETUP_CORE_DIR="$core_checkout" \
    OSSETUP_PERSONAL_DIR="$personal_dir" \
    OSSETUP_BOOTSTRAP_SKIP_INSTALL=1 \
    bash "$BATS_TEST_DIRNAME/../bin/raw-bootstrap.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bootstrap initialized (install skipped)"* ]]

  [ -f "$personal_dir/.ossetup-workspace.json" ]
  [ -d "$personal_dir/manifests" ]
  [ -d "$personal_dir/hooks" ]
  [ -d "$personal_dir/dotfiles" ]
  [ -d "$personal_dir/functions" ]

  run jq -r '.mode' "$personal_dir/.ossetup-workspace.json"
  [ "$status" -eq 0 ]
  [ "$output" = "personal-only" ]

  run jq -r '.core_repo_path' "$personal_dir/.ossetup-workspace.json"
  [ "$status" -eq 0 ]
  [ "$output" = "$core_checkout" ]
}

@test "core raw-bootstrap delegates to personal bootstrap script" {
  local fixture_repo="$BATS_TEST_TMPDIR/personal-fixture"
  local checkout_dir="$BATS_TEST_TMPDIR/personal-checkout"
  create_personal_repo_fixture "$fixture_repo"

  run env \
    OSSETUP_PERSONAL_REPO_URL="file://$fixture_repo" \
    OSSETUP_PERSONAL_REPO_REF="main" \
    OSSETUP_PERSONAL_DIR="$checkout_dir" \
    bash "$BATS_TEST_DIRNAME/../bin/raw-bootstrap.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"personal-bootstrap-ok"* ]]
}

@test "core raw-bootstrap supports legacy env aliases" {
  local core_src="$BATS_TEST_DIRNAME/.."
  local core_checkout="$BATS_TEST_TMPDIR/core-checkout-legacy"
  local personal_dir="$BATS_TEST_TMPDIR/personal-workspace-legacy"

  run env \
    OSSETUP_REPO_URL="file://$core_src" \
    OSSETUP_REPO_REF="main" \
    OSSETUP_INSTALL_DIR="$core_checkout" \
    OSSETUP_PERSONAL_DIR="$personal_dir" \
    OSSETUP_BOOTSTRAP_SKIP_INSTALL=1 \
    bash "$BATS_TEST_DIRNAME/../bin/raw-bootstrap.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bootstrap initialized (install skipped)"* ]]
  [ -f "$personal_dir/.ossetup-workspace.json" ]
}
