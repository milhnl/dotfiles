[[ $PATH == *lazyload* ]] \
    || emulate sh -c '. "${XDG_CONFIG_HOME:-$HOME/.config}/sh/profile.sh"'
emulate sh -c '. "$XDG_CONFIG_HOME/sh/rc.sh"'

# History ---------------------------------------------------------------------
if [ -z "${SHELL_SESSION_HISTFILE_SHARED-}" ]; then
    HISTFILE="$XDG_DATA_HOME/zsh/history"
fi
HISTSIZE=1000000
SAVEHIST=1000000
setopt HIST_FIND_NO_DUPS
setopt appendhistory
setopt extendedhistory
daemon mkdir -p "$XDG_DATA_HOME/zsh"

# Fuzzy find ------------------------------------------------------------------
FUZZYFINDER="$(command -v fzf || command -v fzy 2>/dev/null)"
if [ -n "$FUZZYFINDER" ]; then
    function fz-history-widget {
        BUFFER="$(fc -lnr 1 \
            | sed 's/^[ \t]*//' \
            | awk '!seen[$0]++'\
            | $FUZZYFINDER )"
        CURSOR=$#BUFFER #Move cursor to end of line. Looks nice
        
        zle redisplay #Make sure the prompt is still there
    }

    function fz-branch-widget {
        LBUFFER+="$(git for-each-ref --sort=-committerdate refs/heads/ \
                refs/remotes --format='%(refname:short)' \
            | sed 's/^origin\///' \
            | awk '!seen[$0]++'\
            | $FUZZYFINDER )"
        zle redisplay
    }
    
    function fz-ctrlp-widget {
        local file="$( \
            (git ls-files --cached --others --exclude-standard 2>/dev/null \
                    || rg --files) \
                | $FUZZYFINDER \
                | sed "/[\$~\"*()' ]/{s/'/'\\\\''/g;s/^/'/;s/\$/'/;}")"
        if [ -n "$file" ]; then
            zle push-input
            BUFFER="e $file"
            zle redisplay
            zle accept-line
        else
            zle redisplay
        fi
    }

    function fz-grep-widget {
        setopt local_options extended_glob
        tput smcup
        local out=("${(@f)$(rfv)}")

        tput rmcup
        if [ -n "${out[2]}" ]; then
            local query="${out[1]}"
            local file="${out[2]/(#b)(*):[0-9]#:[0-9]#:*/$match[1]}"
            local line="$(( ${out[2]/(#b)*:([0-9]#):[0-9]#:*/$match[1]} - 1 ))"
            local col="$(( ${out[2]/(#b)*:[0-9]#:([0-9]#):*/$match[1]} - 1 ))"
            zle push-input
            BUFFER="e +'{$line#${col}p /$query/}' $file"
            zle redisplay
            zle accept-line
        else
            zle redisplay
        fi
    }

    zle -N fz-history-widget
    bindkey -M viins '^R' fz-history-widget
    bindkey -M vicmd '^R' fz-history-widget
    zle -N fz-branch-widget
    bindkey -M viins '^B' fz-branch-widget
    bindkey -M vicmd '^B' fz-branch-widget
    zle -N fz-ctrlp-widget
    bindkey -M viins '^P' fz-ctrlp-widget
    bindkey -M vicmd '^P' fz-ctrlp-widget
    bindkey -M vicmd '^[p' fz-ctrlp-widget
    bindkey -M viins '^[p' fz-ctrlp-widget
    zle -N fz-grep-widget
    bindkey -M vicmd '^[f' fz-grep-widget
    bindkey -M viins '^[f' fz-grep-widget
    bindkey -M vicmd '^F' fz-grep-widget
    bindkey -M viins '^F' fz-grep-widget
fi

# Prompt definition -----------------------------------------------------------
if [ -z "$SSH_CLIENT" ] && [ -z "$SSH_TTY" ] && [ "$UID" -ne 0 ]; then
    PROMPT='%B%1~%(?..%F{red})%#%f%b '
else
    PROMPT='%B%n@%m %1~%(?..%F{red})%#%f%b '
fi
REPORTTIME=5
zle_highlight=(default:bold)

function precmd {
    if [ "$TERM_PROGRAM" != Apple_Terminal ]; then
        printf "\e]0;%s\a" "$(basename "$PWD")"
    else
        printf "\e]0;\a"
    fi
    RPROMPT="$(git_promptline)"
}

function preexec {
    if [ "$TERM_PROGRAM" != Apple_Terminal ]; then
        printf "\e]0;%s\a" "$1"
    fi
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

bindkey -v
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char

backward-kill-dir () {
    local WORDCHARS=${WORDCHARS/\/}
    zle backward-kill-word
}
zle -N backward-kill-dir
bindkey '^W' backward-kill-dir

#Copy/paste
function clipboard-copy {
    zle vi-yank
    print -rn -- "$CUTBUFFER" | vis-clipboard --copy
    zle redisplay
}
zle -N clipboard-copy
bindkey -M visual 'Y' clipboard-copy
function clipboard-paste {
    CUTBUFFER="$(vis-clipboard --paste \
        | sed '/https:[^ ]*$/s_www.youtube.com/watch?v=_youtu.be/_')"
    zle vi-put-after
    zle redisplay
}
zle -N clipboard-paste
bindkey -M vicmd 'P' clipboard-paste

# Completion ------------------------------------------------------------------
FPATH="$XDG_DATA_HOME/zsh/site-functions:$FPATH"
emulate sh -c '(chmod -R go-w "$XDG_DATA_HOME/zsh" &)'

zstyle ':completion:*' completer _complete _ignored
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s

zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}'
zstyle :compinstall filename "$HOME"'/.zshrc'

autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit;
else
    compinit -C;
    ({ sleep 2; zcompile "${ZDOTDIR:-$HOME}/.zcompdump" }&)
fi;

unsetopt beep notify BG_NICE
setopt interactivecomments

# Workspace switcher ----------------------------------------------------------
case "$(command -v workspace 2>/dev/null)" in
*/lazyload/workspace|"")
    w() {
        unset -f w
        eval "$(workspace print-zsh-setup w)"
        rehash
        w "$@"
    }
    ;;
*)
    eval "$(workspace print-zsh-setup w)"
    ;;
esac
