# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- 1. ENVIRONMENT VARIABLES & PATHS ---
# Define paths first so all subsequent tools can find them
typeset -U path PATH

# Browser Configuration
export CHROME_EXECUTABLE="/usr/bin/google-chrome"

# Android SDK Configuration
if [[ -d /opt/development_tools/AndroidStudio/sdks ]]; then
  export ANDROID_SDK_ROOT="/opt/development_tools/AndroidStudio/sdks"
else
  if [[ "$OSTYPE" == darwin* ]]; then
    export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
  else
    export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/android-sdk}"
  fi
fi
export ANDROID_HOME=$ANDROID_SDK_ROOT
export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin
export PATH="$HOME/.local/bin:$PATH"

# Puro & Flutter Configuration
if [[ -d /opt/development_tools/puro ]]; then
  export PURO_ROOT="/opt/development_tools/puro"
else
  export PURO_ROOT="${PURO_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/puro}"
fi
export PATH="$PATH:$PURO_ROOT/bin"
export PATH="$PATH:$PURO_ROOT/shared/pub_cache/bin"
export PATH="$PATH:$PURO_ROOT/envs/default/flutter/bin"

# npm global prefix (avoid sudo for global installs)
export NPM_CONFIG_PREFIX="${NPM_CONFIG_PREFIX:-$HOME/.npm-global}"
export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

# --- Custom Functions (XDG) ---
# >>> custom functions >>>
ZSH_CUSTOM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
if [[ -d "$ZSH_CUSTOM_DIR/functions" ]]; then
  fpath=("$ZSH_CUSTOM_DIR/functions" $fpath)
  autoload -Uz "$ZSH_CUSTOM_DIR"/functions/*(:t)
fi
# <<< custom functions <<<

# --- 2. ZIM FRAMEWORK INITIALIZATION ---
# Initialize Zimfw modules before other tool completions to avoid "already initialized" warnings
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi

ZIM_CONFIG_FILE=${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc}
# Initialize (or re-init) when init.zsh is missing or older than the config.
if [[ ! -f ${ZIM_HOME}/init.zsh || ! -f ${ZIM_CONFIG_FILE} || ${ZIM_HOME}/init.zsh -ot ${ZIM_CONFIG_FILE} ]]; then
  source ${ZIM_HOME}/zimfw.zsh init
fi
if [[ -z ${ZIM_INIT_DONE-} ]]; then
  # Starship prompt needs to be initialized before the transient prompt module loads.
  if (( ${+commands[starship]} )); then
    eval "$(starship init zsh)"
  fi
  # Transient prompt: hide previous prompts after each command
  TRANSIENT_PROMPT_TRANSIENT_PROMPT=''
  TRANSIENT_PROMPT_TRANSIENT_RPROMPT=''
  source ${ZIM_HOME}/init.zsh
  ZIM_INIT_DONE=1
fi

# --- 3. COMPATIBILITY LAYER ---
# Fixes "command not found: complete" by enabling Bash completion support in Zsh
autoload -Uz bashcompinit && bashcompinit

# --- 4. CUSTOM TOOLS & VERSION MANAGEMENT ---
# Load version managers and tool-specific scripts

# zoxide (smart cd)
if (( ${+commands[zoxide]} )); then
  eval "$(zoxide init zsh)"
fi

# asdf Version Manager
if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
  . "$HOME/.asdf/asdf.sh"
  [[ -f "$HOME/.asdf/completions/asdf.bash" ]] && . "$HOME/.asdf/completions/asdf.bash"
fi

# Dart CLI Completion
[[ -f /home/emanon/.dart-cli-completion/zsh-config.zsh ]] && . /home/emanon/.dart-cli-completion/zsh-config.zsh

# --- 5. PROMPT CONFIGURATION ---
# Powerlevel10k (disabled)
# [[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# >>> llmproxy >>>
export CLIPROXY_HOME="$HOME/cliproxyapi/llmproxy-config"
[[ -f "$CLIPROXY_HOME/.llmproxy.zsh" ]] && source "$CLIPROXY_HOME/.llmproxy.zsh"
# <<< llmproxy <<<
