# --- 1. ENVIRONMENT VARIABLES & PATHS ---
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

# PATH (base + SDKs)
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"

# --- 2. CUSTOM FUNCTIONS ---
# >>> custom functions >>>
ZSH_CUSTOM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
if [[ -d "$ZSH_CUSTOM_DIR/functions" ]]; then
  fpath=("$ZSH_CUSTOM_DIR/functions" $fpath)
  autoload -Uz "$ZSH_CUSTOM_DIR"/functions/*(:t)
fi
# <<< custom functions <<<

# --- 3. SHELL FRAMEWORK (ZIM) ---
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
if [[ ! -f ${ZIM_HOME}/init.zsh || ! -f ${ZIM_CONFIG_FILE} || ${ZIM_HOME}/init.zsh -ot ${ZIM_CONFIG_FILE} ]]; then
  source ${ZIM_HOME}/zimfw.zsh init
fi
if [[ -z ${ZIM_INIT_DONE-} ]]; then
  # Initialize Starship before Zim modules so prompt hooks are ready.
  if (( ${+commands[starship]} )); then
    eval "$(starship init zsh)"
  fi

  # zsh-transient-prompt settings: keep Starship as active prompt,
  # collapse previous prompts to a minimal shell character.
  TRANSIENT_PROMPT_TRANSIENT_PROMPT='%# '
  TRANSIENT_PROMPT_TRANSIENT_RPROMPT=''

  source ${ZIM_HOME}/init.zsh
  zle_highlight=(${zle_highlight:#paste:*} "paste:none")
  ZIM_INIT_DONE=1
fi

# --- 4. TOOLS & COMPLETIONS ---
# mise (all-in-one runtime manager)
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate --shims zsh)"
fi

# Dart CLI Completion
[[ -f /home/emanon/.dart-cli-completion/zsh-config.zsh ]] && . /home/emanon/.dart-cli-completion/zsh-config.zsh

# --- 5. PROMPT & EXTRAS ---

# >>> llmproxy >>>
export CLIPROXY_HOME="$HOME/cliproxyapi/llmproxy-config"
[[ -f "$CLIPROXY_HOME/src/llmproxy-bootstrap-loader.zsh" ]] && source "$CLIPROXY_HOME/src/llmproxy-bootstrap-loader.zsh"
# <<< llmproxy <<<
