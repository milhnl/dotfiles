[[ -n "$OS" ]] \
    || emulate sh -c '. "${XDG_CONFIG_HOME:-$HOME/.config}/shell/profile.sh"'
[[ -f "$XDG_CONFIG_HOME/shell/rc.sh" ]] \
    && emulate sh -c '. "$XDG_CONFIG_HOME/shell/rc.sh"'

# History ---------------------------------------------------------------------
HISTFILE="$XDG_DATA_HOME/zsh/history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_FIND_NO_DUPS
setopt appendhistory

# Fuzzy find ------------------------------------------------------------------
[[ -f "$PREFIX/lib/fzy.zsh" ]] \
    && . "$PREFIX/lib/fzy.zsh"

# Prompt definition -----------------------------------------------------------
PROMPT='%B[%n@%m %1~]%(?..%F{red})%#%f%b '

function precmd {
    RPROMPT="$(git_promptline)"
}

MAILCHECK=0

# Input customization ---------------------------------------------------------
if [ "$TERM" = "linux" ]; then
    cursor_ins="\033[?5c"
    cursor_cmd="\033[?6c"
    
else
    cursor_ins="\033[6 q"
    cursor_cmd="\033[2 q"
fi
function zle-keymap-select {
    if [ $KEYMAP = vicmd ]; then
        printf "$cursor_cmd"
    else
        printf "$cursor_ins"
    fi
}
function zle-line-init {
    zle -K viins
    printf "$cursor_ins"
}
function zle-line-finish {
    printf "$cursor_cmd"
}
zle -N zle-keymap-select
zle -N zle-line-init
zle -N zle-line-finish

function bindkey-ctrl2esc {
    eval "function zle-ctrl2esc-$2 { zle vi-cmd-mode; zle $2; };"
    zle -N "zle-ctrl2esc-$2"
    bindkey -M viins "$1" "zle-ctrl2esc-$2"
}
bindkey -v
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey-ctrl2esc '^K' up-line-or-history

backward-kill-dir () {
    local WORDCHARS=${WORDCHARS/\/}
    zle backward-kill-word
}
zle -N backward-kill-dir
bindkey '^W' backward-kill-dir

# Completion ------------------------------------------------------------------
fpath=("$XDG_DATA_HOME/zsh/site-functions" $fpath)
emulate sh -c '(chmod -R go-w "$XDG_DATA_HOME/zsh" &)'

zstyle ':completion:*' completer _complete _ignored
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}'
zstyle :compinstall filename "$HOME"'/.zshrc'

autoload -Uz compinit

for dump in ~/.zcompdump(N.mh+24); do
  compinit
done

compinit -C
unsetopt beep notify BG_NICE
setopt interactivecomments
