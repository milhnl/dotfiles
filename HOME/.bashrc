[[ $PATH == *lazyload* ]] \
    || . "${XDG_CONFIG_HOME:-$HOME/.config}/sh/profile.sh"
[[ $- != *i* ]] && return
# If this should be zsh, switch (WSL)
[[ $SHLVL == 1 ]] \
    && [[ "$(getent passwd $LOGNAME|cut -d: -f7)" == */zsh ]] 2>/dev/null \
    && exec zsh
source "$XDG_CONFIG_HOME/sh/rc.sh"

! [ -d "$PREFIX/lib/asdf" ] || . $PREFIX/lib/asdf/completions/asdf.bash

# History ---------------------------------------------------------------------
export HISTFILE="$XDG_DATA_HOME/bash/history"
export HISTSIZE=10000
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL="erasedups:ignoreboth"
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"
HISTTIMEFORMAT='%F %T '
shopt -s histappend cmdhist

# Shell settings --------------------------------------------------------------
shopt -s globstar nocaseglob checkwinsize autocd dirspell cdspell 2>/dev/null

# Fuzzy find ------------------------------------------------------------------
FUZZYFINDER="$(command -v fzf || command -v fzy 2>/dev/null)"
if [ -n "$FUZZYFINDER" ]; then
    set -o vi #readline is not loaded yet or whatever
    function fz-history {
        fc -lnr 1 \
            | sed 's/^[ \t]*//' \
            | awk '!seen[$0]++' \
            | "$FUZZYFINDER"
    }

    if [[ ! -o vi ]]; then
        bind '"\er": redraw-current-line'
        bind '"\e^": history-expand-line'
        bind '"\C-r": " \C-e\C-u$(fz-history||true)\e\C-e\e^\er\n"'
    else
        bind '"\C-x\C-a": vi-movement-mode'
        bind '"\C-x\C-e": shell-expand-line'
        bind '"\C-x\C-r": redraw-current-line'
        bind '"\C-x^": history-expand-line'
        bind '"\C-r": "\C-x\C-addi`fz-history||:`\C-x\C-e\C-x^\C-x\C-a$a\C-x\C-r"'
        bind -m vi-command '"\C-r": "i\C-r"'
    fi
fi

# Prompt definition -----------------------------------------------------------
BOLD=$'\033[0;1m' #base01
INVIS=$'\033[0;30m'
RED=$'\033[1;31m'
NONE=$'\033[m'

configure_prompt() {
    local ROW COL
    IFS=\; read -sdR -p $'\E[6n' ROW COL
    PS1="\[$([ "$COL" -eq 1 ] && printf '\\r' || printf '\\n')\]"
    sc="$([ "$1" -eq 0 ] || echo "$RED")"
    if [ -z "$SSH_CLIENT" ] && [ -z "$SSH_TTY" ] && [ "$UID" -ne 0 ]; then
        PS1="${PS1}"'\[$BOLD\]\W\[$sc\]\$\[$NONE\] '
    else
        PS1="${PS1}"'\[$BOLD\]\u@\h\[$INVIS\]:\[$BOLD\]\W\[$sc\]\$\[$NONE\] '
    fi
}

PROMPT_COMMAND='configure_prompt $?'
