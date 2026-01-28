#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES_DIR="$REPO_ROOT/dotfiles"

log() {
  printf "%s\n" "$*"
}

backup_and_copy() {
  local src="$1"
  local dst="$2"

  if [[ -e "$dst" ]]; then
    local ts
    ts="$(date +%Y%m%d%H%M%S)"
    cp -f "$dst" "${dst}.bak.${ts}"
  fi

  mkdir -p "$(dirname "$dst")"
  cp -f "$src" "$dst"
}

SUDO=""

ensure_sudo() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    SUDO=""
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    log "==> Sudo authentication required"
    sudo -v
    SUDO="sudo"
    return 0
  fi

  log "sudo not found. Please run as root or install sudo."
  return 1
}

install_packages_debian() {
  ensure_sudo
  $SUDO apt-get update
  $SUDO apt-get install -y zsh git curl wget unzip ca-certificates fzf openjdk-17-jdk python3 xz-utils

  # Optional packages (may not exist in older repos)
  set +e
  $SUDO apt-get install -y starship zoxide
  set -e
}

install_packages_fedora() {
  ensure_sudo
  $SUDO dnf install -y zsh git curl wget unzip ca-certificates fzf starship zoxide java-17-openjdk-devel python3
}

install_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    log "==> Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Ensure brew is on PATH for current session
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_packages_macos() {
  install_homebrew
  brew update
  brew install zsh git curl wget unzip starship zoxide fzf python@3
  brew install --cask temurin
}

install_mise() {
  local platform="$1"

  if command -v mise >/dev/null 2>&1; then
    return
  fi

  log "==> Installing mise"

  case "$platform" in
    macos)
      install_homebrew
      brew install mise
      ;;
    *)
      if ! command -v curl >/dev/null 2>&1; then
        log "curl not found; cannot install mise."
        return
      fi
      if ! command -v sh >/dev/null 2>&1; then
        log "sh not found; cannot install mise."
        return
      fi
      curl -fsSL https://mise.jdx.dev/install.sh | sh
      export PATH="$HOME/.local/bin:$PATH"
      ;;
  esac
}

activate_mise_for_script() {
  if command -v mise >/dev/null 2>&1; then
    # Ensure mise-managed shims are available in this script
    eval "$(mise activate bash)"
  fi
}

install_mise_tools() {
  if ! command -v mise >/dev/null 2>&1; then
    log "mise not found; skipping tool install."
    return
  fi

  activate_mise_for_script
  log "==> Installing tools via mise"
  mise install
}

setup_npm_prefix() {
  if ! command -v npm >/dev/null 2>&1; then
    log "npm not found; skipping npm global setup."
    return
  fi

  local npm_prefix="${NPM_CONFIG_PREFIX:-$HOME/.npm-global}"
  mkdir -p "$npm_prefix/bin"
  npm config set prefix "$npm_prefix"
  export PATH="$npm_prefix/bin:$PATH"
}

install_npm_tools() {
  if ! command -v npm >/dev/null 2>&1; then
    log "npm not found; skipping global npm tools."
    return
  fi

  setup_npm_prefix

  log "==> Installing global npm tools (claude-code, codex)"
  set +e
  npm install -g @anthropic-ai/claude-code @openai/codex
  set -e
}

get_cmdline_tools_url() {
  local host_os="$1"
  local repo_url="https://dl.google.com/android/repository/repository2-1.xml"

  if ! command -v python3 >/dev/null 2>&1; then
    return 1
  fi

  python3 - "$repo_url" "$host_os" <<'PY'
import sys
import urllib.request
import xml.etree.ElementTree as ET

repo_url = sys.argv[1]
host_os = sys.argv[2]

data = urllib.request.urlopen(repo_url).read()
root = ET.fromstring(data)

candidates = []
for pkg in root.findall("remotePackage"):
    path = pkg.get("path", "")
    if not path.startswith("cmdline-tools;"):
        continue
    channel = pkg.find("channelRef")
    channel_ref = channel.get("ref") if channel is not None else ""

    rev = pkg.find("revision")
    def get(tag):
        node = rev.find(tag) if rev is not None else None
        return int(node.text) if node is not None else 0
    version = (get("major"), get("minor"), get("micro"))

    archives = pkg.find("archives")
    if archives is None:
        continue
    for arch in archives.findall("archive"):
        host = arch.findtext("host-os")
        if host != host_os:
            continue
        url = arch.findtext("complete/url")
        if not url:
            continue
        candidates.append((channel_ref == "channel-0", version, url))

if not candidates:
    sys.exit(1)

candidates.sort(key=lambda x: (x[0], x[1]), reverse=True)
url = candidates[0][2]
if not url.startswith("http"):
    url = "https://dl.google.com/android/repository/" + url
print(url)
PY
}

install_android_sdk() {
  if command -v sdkmanager >/dev/null 2>&1; then
    log "==> Updating Android SDK components"
    yes | sdkmanager --licenses >/dev/null 2>&1 || true
    sdkmanager --install "platform-tools" "cmdline-tools;latest" >/dev/null 2>&1 || true
    return
  fi

  local host_os
  case "$OSTYPE" in
    darwin*) host_os="macosx" ;;
    linux*) host_os="linux" ;;
    *) log "Unsupported OS for Android SDK install"; return ;;
  esac

  local sdk_root=""
  if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
    sdk_root="$ANDROID_SDK_ROOT"
  elif [[ -n "${ANDROID_HOME:-}" ]]; then
    sdk_root="$ANDROID_HOME"
  elif [[ "$host_os" == "macosx" ]]; then
    sdk_root="$HOME/Library/Android/sdk"
  else
    sdk_root="${XDG_DATA_HOME:-$HOME/.local/share}/android-sdk"
  fi

  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    log "curl or wget is required to download Android cmdline tools."
    return
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    log "python3 is required to resolve the Android cmdline tools download URL."
    return
  fi

  log "==> Installing Android SDK cmdline tools to: $sdk_root"
  mkdir -p "$sdk_root"

  local url
  url="$(get_cmdline_tools_url "$host_os")" || {
    log "Failed to resolve Android cmdline tools URL."
    return
  }

  local tmpdir archive
  tmpdir="$(mktemp -d)"
  archive="$tmpdir/commandlinetools"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$archive"
  else
    wget -O "$archive" "$url"
  fi

  local tools_dir="$sdk_root/cmdline-tools"
  mkdir -p "$tools_dir"

  case "$url" in
    *.zip)
      unzip -q "$archive" -d "$tools_dir"
      ;;
    *.tar.gz|*.tgz)
      tar -xzf "$archive" -C "$tools_dir"
      ;;
    *)
      log "Unknown archive type: $url"
      return
      ;;
  esac

  if [[ -d "$tools_dir/cmdline-tools" ]]; then
    rm -rf "$tools_dir/latest"
    mkdir -p "$tools_dir/latest"
    mv "$tools_dir/cmdline-tools/"* "$tools_dir/latest/"
    rmdir "$tools_dir/cmdline-tools" 2>/dev/null || true
  fi

  mkdir -p "$HOME/.android"
  touch "$HOME/.android/repositories.cfg"

  export ANDROID_SDK_ROOT="$sdk_root"
  export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

  local sdkmanager_bin="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
  if [[ -x "$sdkmanager_bin" ]]; then
    yes | "$sdkmanager_bin" --licenses >/dev/null 2>&1 || true
    "$sdkmanager_bin" --install "platform-tools" "cmdline-tools;latest" >/dev/null 2>&1 || true
  else
    log "sdkmanager not found after install; check $ANDROID_SDK_ROOT"
  fi
}

setup_dotfiles() {
  log "==> Installing dotfiles"
  backup_and_copy "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  backup_and_copy "$DOTFILES_DIR/.zimrc" "$HOME/.zimrc"

  if [[ -f "$DOTFILES_DIR/.config/starship.toml" ]]; then
    backup_and_copy "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
  fi

  if [[ -f "$DOTFILES_DIR/.config/mise/config.toml" ]]; then
    backup_and_copy "$DOTFILES_DIR/.config/mise/config.toml" "$HOME/.config/mise/config.toml"
  fi

  if [[ -f "$DOTFILES_DIR/.ssh/config" ]]; then
    mkdir -p "$HOME/.ssh"
    backup_and_copy "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh/config"
  fi

  if [[ -f "$DOTFILES_DIR/.config/Code/User/settings.json" ]]; then
    backup_and_copy "$DOTFILES_DIR/.config/Code/User/settings.json" \
      "$HOME/.config/Code/User/settings.json"
  fi

  if [[ -f "$DOTFILES_DIR/.config/Code/User/keybindings.json" ]]; then
    backup_and_copy "$DOTFILES_DIR/.config/Code/User/keybindings.json" \
      "$HOME/.config/Code/User/keybindings.json"
  fi
}

setup_functions() {
  "$REPO_ROOT/bin/setup-zsh-functions.sh"
}

detect_platform() {
  local uname_out
  uname_out="$(uname -s)"
  if [[ "$uname_out" == "Darwin" ]]; then
    echo "macos"
    return
  fi

  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    case "${ID:-}" in
      ubuntu|debian|linuxmint|pop)
        echo "debian"
        return
        ;;
      fedora|rhel|centos)
        echo "fedora"
        return
        ;;
    esac
  fi

  echo "unsupported"
}

main() {
  local platform
  platform="$(detect_platform)"

  case "$platform" in
    debian)
      install_packages_debian
      ;;
    fedora)
      install_packages_fedora
      ;;
    macos)
      install_packages_macos
      ;;
    *)
      log "Unsupported platform. Supported: Ubuntu/Debian, Fedora, macOS."
      exit 1
      ;;
  esac

  setup_dotfiles
  setup_functions
  install_mise "$platform"
  install_mise_tools
  install_android_sdk
  install_npm_tools

  log "==> Done. Restart your shell or run: source ~/.zshrc"
}

main "$@"
