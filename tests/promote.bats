#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/helpers/workspace-fixture.bash"

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true
  setup_workspace_in_repo "$work"

  mkdir -p "$work/manifests/layers/targets" "$work/manifests/state/linux-debian"

  cat > "$work/manifests/layers/targets/linux-debian.yaml" <<'JSON'
{
  "packages": {
    "apt": ["old-apt"],
    "flatpak": ["old-flatpak"],
    "snap": ["old-snap"]
  },
  "npm_globals": ["old-npm"]
}
JSON

  cat > "$work/manifests/state/linux-debian/apt-manual.txt" <<'TXT'
curl
git
TXT

  cat > "$work/manifests/state/linux-debian/flatpak-apps.txt" <<'TXT'
org.example.NewFlatpak
TXT

  cat > "$work/manifests/state/linux-debian/snap-list.txt" <<'TXT'
new-snap
TXT

  cat > "$work/manifests/state/linux-debian/npm-globals.txt" <<'TXT'
@openai/codex
state-npm-cli
TXT
}

@test "promote preview prints plan and does not mutate manifests" {
  before_hash="$(sha256sum "$work/manifests/layers/targets/linux-debian.yaml" | awk '{print $1}')"

  run "$work/bin/ossetup" promote --target linux-debian --scope all --from-state latest --preview
  [ "$status" -eq 0 ]
  [[ "$output" == *"PROMOTE PREVIEW"* ]]

  after_hash="$(sha256sum "$work/manifests/layers/targets/linux-debian.yaml" | awk '{print $1}')"
  [ "$before_hash" = "$after_hash" ]
}

@test "promote apply updates target layer from state snapshot" {
  run "$work/bin/ossetup" promote --target linux-debian --scope all --from-state latest --apply
  [ "$status" -eq 0 ]
  [[ "$output" == *"PROMOTE APPLY"* ]]

  [ "$(jq -r '.packages.apt | join(",")' "$work/manifests/layers/targets/linux-debian.yaml")" = "curl,git" ]
  [ "$(jq -r '.packages.flatpak | join(",")' "$work/manifests/layers/targets/linux-debian.yaml")" = "org.example.NewFlatpak" ]
  [ "$(jq -r '.packages.snap | join(",")' "$work/manifests/layers/targets/linux-debian.yaml")" = "new-snap" ]
  [ "$(jq -r '.npm_globals | join(",")' "$work/manifests/layers/targets/linux-debian.yaml")" = "@openai/codex,state-npm-cli" ]
}

@test "promote --scope packages does not change npm_globals" {
  run "$work/bin/ossetup" promote --target linux-debian --scope packages --from-state latest --apply
  [ "$status" -eq 0 ]

  [ "$(jq -r '.packages.apt | join(",")' "$work/manifests/layers/targets/linux-debian.yaml")" = "curl,git" ]
  [ "$(jq -r '.npm_globals | join(",")' "$work/manifests/layers/targets/linux-debian.yaml")" = "old-npm" ]
}

@test "promote requires --target" {
  run "$work/bin/ossetup" promote --scope all --from-state latest --preview
  [ "$status" -eq 64 ]
  [[ "$output" == *"--target is required"* ]]
}

@test "promote rejects invalid scope" {
  run "$work/bin/ossetup" promote --target linux-debian --scope invalid --from-state latest --preview
  [ "$status" -eq 64 ]
  [[ "$output" == *"invalid scope"* ]]
}
