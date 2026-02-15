#!/usr/bin/env bash

if [[ -n "${OSSETUP_PROVIDER_ANDROID_SDK_SH:-}" ]]; then
  return 0
fi
OSSETUP_PROVIDER_ANDROID_SDK_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"

get_cmdline_tools_url() {
  local host_os="$1"
  local repo_url="https://dl.google.com/android/repository/repository2-1.xml"

  python3 - "$repo_url" "$host_os" <<'PY'
import sys
import urllib.request
import xml.etree.ElementTree as ET

repo_url = sys.argv[1]
host_os = sys.argv[2]

data = urllib.request.urlopen(repo_url).read()
root = ET.fromstring(data)

candidates = []
for pkg in root.findall('remotePackage'):
    path = pkg.get('path', '')
    if not path.startswith('cmdline-tools;'):
        continue

    channel = pkg.find('channelRef')
    channel_ref = channel.get('ref') if channel is not None else ''

    rev = pkg.find('revision')
    def get(tag):
        node = rev.find(tag) if rev is not None else None
        return int(node.text) if node is not None else 0
    version = (get('major'), get('minor'), get('micro'))

    archives = pkg.find('archives')
    if archives is None:
        continue

    for arch in archives.findall('archive'):
        host = arch.findtext('host-os')
        if host != host_os:
            continue
        url = arch.findtext('complete/url')
        if not url:
            continue
        candidates.append((channel_ref == 'channel-0', version, url))

if not candidates:
    raise SystemExit(1)

candidates.sort(key=lambda x: (x[0], x[1]), reverse=True)
url = candidates[0][2]
if not url.startswith('http'):
    url = 'https://dl.google.com/android/repository/' + url
print(url)
PY
}

install_android_sdk() {
  local target="$1"
  local dry_run="$2"

  if [[ "$dry_run" == "1" ]]; then
    info "dry-run android sdk install"
    return 0
  fi

  if command -v sdkmanager >/dev/null 2>&1; then
    yes | sdkmanager --licenses >/dev/null 2>&1 || true
    sdkmanager --install "platform-tools" "cmdline-tools;latest" >/dev/null 2>&1 || true
    return 0
  fi

  local host_os sdk_root
  case "$target" in
    macos)
      host_os="macosx"
      sdk_root="${ANDROID_SDK_ROOT:-$OSSETUP_HOME/Library/Android/sdk}"
      ;;
    linux-debian)
      host_os="linux"
      sdk_root="${ANDROID_SDK_ROOT:-${XDG_DATA_HOME:-$OSSETUP_HOME/.local/share}/android-sdk}"
      ;;
    *)
      die "$E_TARGET" "unsupported target for android sdk: $target"
      ;;
  esac

  command -v python3 >/dev/null 2>&1 || {
    warn "python3 not found; skipping android sdk"
    return 0
  }
  command -v curl >/dev/null 2>&1 || {
    warn "curl not found; skipping android sdk"
    return 0
  }

  local url
  url="$(get_cmdline_tools_url "$host_os")" || {
    warn "could not resolve android cmdline tools url"
    return 0
  }

  local tmpdir archive tools_dir
  tmpdir="$(mktemp -d)"
  archive="$tmpdir/cmdline-tools"
  tools_dir="$sdk_root/cmdline-tools"

  mkdir -p "$tools_dir"
  curl -fsSL "$url" -o "$archive"

  case "$url" in
    *.zip)
      unzip -q "$archive" -d "$tools_dir"
      ;;
    *.tar.gz|*.tgz)
      tar -xzf "$archive" -C "$tools_dir"
      ;;
    *)
      warn "unknown android sdk archive format: $url"
      rm -rf "$tmpdir"
      return 0
      ;;
  esac

  if [[ -d "$tools_dir/cmdline-tools" ]]; then
    rm -rf "$tools_dir/latest"
    mkdir -p "$tools_dir/latest"
    mv "$tools_dir/cmdline-tools/"* "$tools_dir/latest/"
    rmdir "$tools_dir/cmdline-tools" 2>/dev/null || true
  fi

  export ANDROID_SDK_ROOT="$sdk_root"
  export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

  local sdkmanager_bin="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
  if [[ -x "$sdkmanager_bin" ]]; then
    yes | "$sdkmanager_bin" --licenses >/dev/null 2>&1 || true
    "$sdkmanager_bin" --install "platform-tools" "cmdline-tools;latest" >/dev/null 2>&1 || true
  fi

  rm -rf "$tmpdir"
}
