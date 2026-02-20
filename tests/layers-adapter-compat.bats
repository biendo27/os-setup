#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true
  export OSSETUP_HOME_DIR="$BATS_TEST_TMPDIR/home"
  mkdir -p "$OSSETUP_HOME_DIR/.config"
  cp "$work/dotfiles/.zshrc" "$OSSETUP_HOME_DIR/.zshrc"
}

@test "install dry-run still works with legacy target manifests only" {
  rm -rf "$work/manifests/layers"

  run "$work/bin/ossetup" install --dry-run --target linux-debian --profile default
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run apt packages"* ]]
  [[ "$output" == *"install complete"* ]]
}

@test "layered manifests override legacy target source when present" {
  cat > "$work/manifests/profiles/default.yaml" <<'JSON'
{
  "name": "default",
  "modules": {
    "packages": true,
    "dotfiles": false,
    "functions": false,
    "mise": false,
    "android_sdk": false,
    "npm_globals": false,
    "secrets": false,
    "global_cli": false
  }
}
JSON

  cat > "$work/manifests/targets/linux-debian.yaml" <<'JSON'
{
  "packages": {
    "apt": ["legacy-only-package"],
    "flatpak": [],
    "snap": []
  },
  "npm_globals": []
}
JSON

  mkdir -p "$work/manifests/layers/targets" "$work/manifests/layers/hosts"
  cat > "$work/manifests/layers/core.yaml" <<'JSON'
{
  "packages": {
    "apt": ["layer-core-package"]
  },
  "npm_globals": []
}
JSON

  cat > "$work/manifests/layers/targets/linux-debian.yaml" <<'JSON'
{
  "packages": {
    "apt": ["layer-target-package"],
    "flatpak": [],
    "snap": []
  },
  "npm_globals": []
}
JSON

  run "$work/bin/ossetup" install --dry-run --target linux-debian --profile default
  [ "$status" -eq 0 ]
  [[ "$output" == *"layer-core-package"* ]]
  [[ "$output" == *"layer-target-package"* ]]
  [[ "$output" != *"legacy-only-package"* ]]
}
