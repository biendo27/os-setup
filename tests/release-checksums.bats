#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/release-checksums.sh" "$work/bin/release-verify.sh" 2>/dev/null || true
  assets="$BATS_TEST_TMPDIR/assets"
  mkdir -p "$assets"
}

@test "release-checksums generates deterministic SHA256SUMS without signing when --no-sign is set" {
  printf 'beta\n' >"$assets/b.txt"
  printf 'alpha\n' >"$assets/a.txt"
  mkdir -p "$assets/nested"
  printf 'gamma\n' >"$assets/nested/c.txt"

  run "$work/bin/release-checksums.sh" --assets-dir "$assets" --no-sign
  [ "$status" -eq 0 ]
  [ -f "$assets/SHA256SUMS" ]
  [ ! -f "$assets/SHA256SUMS.asc" ]

  run awk '{print $2}' "$assets/SHA256SUMS"
  [ "$status" -eq 0 ]
  [ "$output" = $'a.txt\nb.txt\nnested/c.txt' ]

  before="$(cat "$assets/SHA256SUMS")"
  run "$work/bin/release-checksums.sh" --assets-dir "$assets" --no-sign
  [ "$status" -eq 0 ]
  after="$(cat "$assets/SHA256SUMS")"
  [ "$before" = "$after" ]
}

@test "release-checksums fails when assets directory has no release artifacts" {
  run "$work/bin/release-checksums.sh" --assets-dir "$assets" --no-sign
  [ "$status" -eq 65 ]
  [[ "$output" == *"no artifacts found"* ]]
}

@test "release-checksums fails clearly when sign key is invalid" {
  if ! command -v gpg >/dev/null 2>&1; then
    skip "gpg is not available"
  fi

  printf 'artifact\n' >"$assets/artifact.txt"
  run "$work/bin/release-checksums.sh" --assets-dir "$assets" --sign-key "INVALID-KEY-ID"
  [ "$status" -eq 65 ]
  [[ "$output" == *"gpg signing failed"* ]]
}
