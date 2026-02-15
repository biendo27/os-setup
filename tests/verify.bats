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
}

@test "verify writes report" {
  run "$work/bin/ossetup" verify --report
  [ "$status" -eq 0 ]
  [[ "$output" == *"report:"* ]]
  report_path="$(printf '%s\n' "$output" | awk '/report:/ {print $2}' | tail -n1)"
  [ -f "$report_path" ]
  grep -q "PASS" "$report_path"
}
