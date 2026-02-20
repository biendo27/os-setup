#!/usr/bin/env bats

setup() {
  work="$BATS_TEST_TMPDIR/work"
  cp -R "$BATS_TEST_DIRNAME/.." "$work"
  chmod +x "$work/bin/ossetup" 2>/dev/null || true

  export OSSETUP_HOME_DIR="$BATS_TEST_TMPDIR/home"
  mkdir -p "$OSSETUP_HOME_DIR"
  cp "$work/dotfiles/.zshrc" "$OSSETUP_HOME_DIR/.zshrc"
  cp "$work/dotfiles/.zimrc" "$OSSETUP_HOME_DIR/.zimrc"
  mkdir -p "$OSSETUP_HOME_DIR/.config"
  cp "$work/dotfiles/.config/starship.toml" "$OSSETUP_HOME_DIR/.config/starship.toml"
  mkdir -p "$OSSETUP_HOME_DIR/.config/mise"
  cp "$work/dotfiles/.config/mise/config.toml" "$OSSETUP_HOME_DIR/.config/mise/config.toml"
  mkdir -p "$OSSETUP_HOME_DIR/.ssh"
  cp "$work/dotfiles/.ssh/config" "$OSSETUP_HOME_DIR/.ssh/config"
  mkdir -p "$OSSETUP_HOME_DIR/.config/Code/User"
  cp "$work/dotfiles/.config/Code/User/settings.json" "$OSSETUP_HOME_DIR/.config/Code/User/settings.json"
  cp "$work/dotfiles/.config/Code/User/keybindings.json" "$OSSETUP_HOME_DIR/.config/Code/User/keybindings.json"
  mkdir -p "$OSSETUP_HOME_DIR/.config/zsh/functions"
  cp "$work/functions"/* "$OSSETUP_HOME_DIR/.config/zsh/functions/"

  target="linux-debian"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    target="macos"
  fi
  echo "$target" > "$BATS_TEST_TMPDIR/current-target"

  mkdir -p "$work/manifests/layers/targets" "$work/manifests/state/$target"
  cat > "$work/manifests/layers/core.yaml" <<'JSON'
{
  "packages": {},
  "npm_globals": []
}
JSON

  if [[ "$target" == "linux-debian" ]]; then
    cat > "$work/manifests/layers/targets/linux-debian.yaml" <<'JSON'
{
  "packages": {
    "apt": ["curl", "git"],
    "flatpak": [],
    "snap": []
  },
  "npm_globals": ["state-npm-cli"]
}
JSON
    printf 'curl\ngit\n' > "$work/manifests/state/linux-debian/apt-manual.txt"
    : > "$work/manifests/state/linux-debian/flatpak-apps.txt"
    : > "$work/manifests/state/linux-debian/snap-list.txt"
    printf 'state-npm-cli\n' > "$work/manifests/state/linux-debian/npm-globals.txt"
  else
    cat > "$work/manifests/layers/targets/macos.yaml" <<'JSON'
{
  "packages": {
    "brew": ["curl", "git"],
    "brew_cask": []
  },
  "npm_globals": ["state-npm-cli"]
}
JSON
    printf 'curl\ngit\n' > "$work/manifests/state/macos/brew-formula.txt"
    : > "$work/manifests/state/macos/brew-casks.txt"
    printf 'state-npm-cli\n' > "$work/manifests/state/macos/npm-globals.txt"
  fi
}

@test "verify --strict passes when state snapshots match resolved manifests" {
  run "$work/bin/ossetup" verify --strict --report
  [ "$status" -eq 0 ]
  [[ "$output" == *"report:"* ]]

  report_path="$(printf '%s\n' "$output" | awk '/report:/ {print $2}' | tail -n1)"
  [ -f "$report_path" ]
  grep -q "PASS strict" "$report_path"
}

@test "verify --strict fails on contract drift" {
  target="$(cat "$BATS_TEST_TMPDIR/current-target")"
  if [[ "$target" == "linux-debian" ]]; then
    printf 'curl\ngit\ndrift-package\n' > "$work/manifests/state/linux-debian/apt-manual.txt"
  else
    printf 'curl\ngit\ndrift-package\n' > "$work/manifests/state/macos/brew-formula.txt"
  fi

  run "$work/bin/ossetup" verify --strict
  [ "$status" -eq 70 ]
  [[ "$output" == *"strict verification failed"* ]]
}
