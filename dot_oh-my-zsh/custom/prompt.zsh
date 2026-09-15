# Compact prompt shared across Macs.
# Print a directory banner when the working directory changes, then show a
# per-directory command number and timestamp on each prompt.
autoload -Uz add-zsh-hook colors
colors

typeset -g SHARED_PROMPT_LAST_DIR=""
typeset -gi SHARED_PROMPT_COMMAND_NUMBER=0
typeset -ga SHARED_PROMPT_DIR_COLORS=(220 magenta green)
typeset -gi SHARED_PROMPT_COLOR_INDEX=0
typeset -g SHARED_PROMPT_COLOR

shared_prompt_precmd() {
  if [[ "$PWD" != "$SHARED_PROMPT_LAST_DIR" ]]; then
    (( SHARED_PROMPT_COLOR_INDEX = SHARED_PROMPT_COLOR_INDEX % ${#SHARED_PROMPT_DIR_COLORS} + 1 ))
    SHARED_PROMPT_COLOR="${SHARED_PROMPT_DIR_COLORS[$SHARED_PROMPT_COLOR_INDEX]}"
    print -P "%B%F{${SHARED_PROMPT_COLOR}}━━━ %~ ━━━%f%b"
    SHARED_PROMPT_LAST_DIR="$PWD"
    SHARED_PROMPT_COMMAND_NUMBER=0
  fi

  (( SHARED_PROMPT_COMMAND_NUMBER++ ))
  PROMPT="%F{${SHARED_PROMPT_COLOR}}${SHARED_PROMPT_COMMAND_NUMBER}%f %F{240}%D{%H:%M:%S}%f "
}

add-zsh-hook -d precmd shared_prompt_precmd 2>/dev/null
add-zsh-hook precmd shared_prompt_precmd
