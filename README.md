# OSSetup

Bootstrap your Zsh environment and tools (no symlinks).

## Install (one command)

```bash
cd /home/emanon/Data/Projects/Program/Scripts/OSSetup
./bin/setup.sh
```

## What it does

- Installs base tools (Zsh, git, curl, etc.) for Ubuntu/Debian, Fedora, macOS
- Installs Java 17 (required for Android SDK tools)
- Installs Node.js (18+) and npm
- Installs `asdf`
- Installs `puro` (best-effort)
- Installs Android SDK cmdline tools (downloads latest from Google)
- Installs global npm tools: Claude Code, OpenAI Codex CLI
- Copies dotfiles into place (backs up existing files)
- Copies custom Zsh functions into `~/.config/zsh/functions/`

## Notes

- Existing files are backed up with a timestamp suffix.
- No symlinks are used.
- Android SDK installs to:
  - macOS: `~/Library/Android/sdk`
  - Linux: `${XDG_DATA_HOME:-~/.local/share}/android-sdk`

