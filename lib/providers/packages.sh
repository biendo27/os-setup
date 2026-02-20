#!/usr/bin/env bash

if [[ -n "${OSSETUP_PROVIDER_PACKAGES_SH:-}" ]]; then
  return 0
fi
OSSETUP_PROVIDER_PACKAGES_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"
source "$OSSETUP_ROOT/lib/core/manifest.sh"

ensure_sudo() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    printf '%s\n' ""
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    sudo -v >/dev/null 2>&1 || die "$E_PRECHECK" "sudo authentication failed"
    printf '%s\n' "sudo"
    return 0
  fi

  die "$E_PRECHECK" "sudo is required for package installation"
}

install_brew_if_missing() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_packages_for_target() {
  local target="$1"
  local dry_run="$2"
  local host_id="${3:-${OSSETUP_HOST_ID:-}}"
  local -a packages=()
  local -a flatpaks=()
  local -a snaps=()
  local -a casks=()

  case "$target" in
    linux-debian)
      mapfile -t packages < <(target_packages "$target" "apt" "$host_id")
      if (( ${#packages[@]} == 0 )); then
        info "no apt packages configured"
        return 0
      fi
      if [[ "$dry_run" == "1" ]]; then
        info "dry-run apt packages: ${packages[*]}"
        mapfile -t flatpaks < <(target_packages "$target" "flatpak" "$host_id")
        mapfile -t snaps < <(target_packages "$target" "snap" "$host_id")
        if (( ${#flatpaks[@]} > 0 )); then
          info "dry-run flatpak apps: ${flatpaks[*]}"
        fi
        if (( ${#snaps[@]} > 0 )); then
          info "dry-run snap apps: ${snaps[*]}"
        fi
        return 0
      fi
      local sudo_cmd
      sudo_cmd="$(ensure_sudo)"
      $sudo_cmd apt-get update
      $sudo_cmd apt-get install -y "${packages[@]}"

      mapfile -t flatpaks < <(target_packages "$target" "flatpak" "$host_id")
      if (( ${#flatpaks[@]} > 0 )); then
        if command -v flatpak >/dev/null 2>&1; then
          local app
          for app in "${flatpaks[@]}"; do
            flatpak install -y flathub "$app" >/dev/null 2>&1 || true
          done
        else
          warn "flatpak not installed; skipping flatpak apps"
        fi
      fi

      mapfile -t snaps < <(target_packages "$target" "snap" "$host_id")
      if (( ${#snaps[@]} > 0 )); then
        if command -v snap >/dev/null 2>&1; then
          local app
          for app in "${snaps[@]}"; do
            $sudo_cmd snap install "$app" >/dev/null 2>&1 || true
          done
        else
          warn "snap not installed; skipping snap apps"
        fi
      fi
      ;;
    macos)
      mapfile -t packages < <(target_packages "$target" "brew" "$host_id")
      if (( ${#packages[@]} == 0 )); then
        info "no brew packages configured"
        return 0
      fi
      if [[ "$dry_run" == "1" ]]; then
        info "dry-run brew packages: ${packages[*]}"
        mapfile -t casks < <(target_packages "$target" "brew_cask" "$host_id")
        if (( ${#casks[@]} > 0 )); then
          info "dry-run brew casks: ${casks[*]}"
        fi
        return 0
      fi
      install_brew_if_missing
      brew update
      brew install "${packages[@]}"

      mapfile -t casks < <(target_packages "$target" "brew_cask" "$host_id")
      if (( ${#casks[@]} > 0 )); then
        brew install --cask "${casks[@]}"
      fi
      ;;
    *)
      die "$E_TARGET" "unsupported target for package provider: $target"
      ;;
  esac
}
