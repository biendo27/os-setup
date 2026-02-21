#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"

  mkdir -p "$work/manifests/layers/targets" "$work/manifests/layers/hosts"

  cat > "$work/manifests/layers/core.yaml" <<'JSON'
{
  "meta": {
    "level": "core",
    "owner": "shared"
  },
  "packages": {
    "apt": ["curl", "jq"]
  },
  "npm_globals": ["core-cli"]
}
JSON

  cat > "$work/manifests/layers/targets/linux-debian.yaml" <<'JSON'
{
  "meta": {
    "level": "target"
  },
  "packages": {
    "apt": ["jq", "git"],
    "flatpak": ["org.example.TargetApp"]
  },
  "npm_globals": ["target-cli"]
}
JSON

  cat > "$work/manifests/layers/hosts/host-01.yaml" <<'JSON'
{
  "meta": {
    "level": "host"
  },
  "packages": {
    "apt": ["git", "zsh"]
  },
  "npm_globals": ["host-cli"]
}
JSON
}

@test "layers resolver merges core target host deterministically" {
  run env OSSETUP_ROOT="$work" bash -lc '
    source "$OSSETUP_ROOT/lib/core/common.sh"
    source "$OSSETUP_ROOT/lib/core/layers.sh"
    resolve_layered_target_manifest_json "linux-debian" "host-01"
  '
  [ "$status" -eq 0 ]

  [ "$(jq -r '.meta.level' <<<"$output")" = "host" ]
  [ "$(jq -r '.meta.owner' <<<"$output")" = "shared" ]
  [ "$(jq -r '.packages.apt | join(",")' <<<"$output")" = "curl,jq,git,zsh" ]
  [ "$(jq -r '.packages.flatpak | join(",")' <<<"$output")" = "org.example.TargetApp" ]
  [ "$(jq -r '.npm_globals | join(",")' <<<"$output")" = "core-cli,target-cli,host-cli" ]
}

@test "layers resolver falls back to core and target when host layer is missing" {
  run env OSSETUP_ROOT="$work" bash -lc '
    source "$OSSETUP_ROOT/lib/core/common.sh"
    source "$OSSETUP_ROOT/lib/core/layers.sh"
    resolve_layered_target_manifest_json "linux-debian" "host-missing"
  '
  [ "$status" -eq 0 ]

  [ "$(jq -r '.meta.level' <<<"$output")" = "target" ]
  [ "$(jq -r '.packages.apt | join(",")' <<<"$output")" = "curl,jq,git" ]
  [ "$(jq -r '.npm_globals | join(",")' <<<"$output")" = "core-cli,target-cli" ]
}

@test "layers resolver applies personal user and host overlays after core layers" {
  local personal="$BATS_TEST_TMPDIR/personal"
  mkdir -p "$personal/manifests/layers/users" "$personal/manifests/layers/hosts"

  cat > "$personal/manifests/layers/users/emanon.yaml" <<'JSON'
{
  "meta": {
    "level": "user"
  },
  "packages": {
    "apt": ["fzf"]
  },
  "npm_globals": ["user-cli"]
}
JSON

  cat > "$personal/manifests/layers/hosts/host-01.yaml" <<'JSON'
{
  "meta": {
    "level": "personal-host"
  },
  "packages": {
    "apt": ["fd-find"]
  },
  "npm_globals": ["personal-host-cli"]
}
JSON

  run env \
    OSSETUP_ROOT="$work" \
    OSSETUP_WORKSPACE_MODE="personal-overrides" \
    OSSETUP_CORE_ROOT="$work" \
    OSSETUP_PERSONAL_ROOT="$personal" \
    OSSETUP_WORKSPACE_USER_ID="emanon" \
    bash -lc '
      source "$OSSETUP_ROOT/lib/core/common.sh"
      source "$OSSETUP_ROOT/lib/core/layers.sh"
      resolve_layered_target_manifest_json "linux-debian" "host-01"
    '
  [ "$status" -eq 0 ]

  [ "$(jq -r '.meta.level' <<<"$output")" = "personal-host" ]
  [ "$(jq -r '.packages.apt | join(",")' <<<"$output")" = "curl,jq,git,zsh,fzf,fd-find" ]
  [ "$(jq -r '.npm_globals | join(",")' <<<"$output")" = "core-cli,target-cli,host-cli,user-cli,personal-host-cli" ]
}
