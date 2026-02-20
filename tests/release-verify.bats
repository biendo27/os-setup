#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/release-checksums.sh" "$work/bin/release-verify.sh" 2>/dev/null || true
  assets="$BATS_TEST_TMPDIR/assets"
  mkdir -p "$assets"
}

create_signed_assets() {
  if ! command -v gpg >/dev/null 2>&1; then
    skip "gpg is not available"
  fi

  export GNUPGHOME="$BATS_TEST_TMPDIR/gnupg"
  mkdir -p "$GNUPGHOME"
  chmod 700 "$GNUPGHOME"

  gpg --batch --pinentry-mode loopback --passphrase '' \
    --quick-generate-key "OSSetup Release Test <release-test@example.invalid>" default default never >/dev/null 2>&1

  key_fpr="$(gpg --list-secret-keys --with-colons | awk -F: '/^fpr:/ {print $10; exit}')"
  [ -n "$key_fpr" ]

  run "$work/bin/release-checksums.sh" --assets-dir "$assets" --sign-key "$key_fpr"
  [ "$status" -eq 0 ]
  [ -f "$assets/SHA256SUMS" ]
  [ -f "$assets/SHA256SUMS.asc" ]
}

@test "release-verify passes when signature and checksums are valid" {
  printf 'artifact-a\n' >"$assets/a.txt"
  printf 'artifact-b\n' >"$assets/b.txt"

  create_signed_assets

  run "$work/bin/release-verify.sh" --assets-dir "$assets"
  [ "$status" -eq 0 ]
  [[ "$output" == *"signature and checksums verified"* ]]
}

@test "release-verify fails when artifact content drifts after checksum generation" {
  printf 'artifact-a\n' >"$assets/a.txt"
  printf 'artifact-b\n' >"$assets/b.txt"

  create_signed_assets
  printf 'tampered\n' >>"$assets/a.txt"

  run "$work/bin/release-verify.sh" --assets-dir "$assets"
  [ "$status" -eq 70 ]
  [[ "$output" == *"checksum verification failed"* ]]
}
