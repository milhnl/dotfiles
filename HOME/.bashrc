[[ $- != *i* ]] && return
# If this should be zsh, switch (WSL)
[[ $SHLVL == 1 ]] && [[ "$(getent passwd $LOGNAME|cut -d: -f7)" == */zsh ]] \
    && exec zsh

[[ -n "$OS" ]] || . "${XDG_CONFIG_HOME:-$HOME/.config}/shell/profile.sh"
[[ -f "$XDG_CONFIG_HOME/shell/rc.sh" ]] \
    && source "$XDG_CONFIG_HOME/shell/rc.sh"

# History ---------------------------------------------------------------------
export HISTFILE="$XDG_DATA_HOME/bash/history"
export HISTSIZE=10000
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL="erasedups:ignoreboth"
shopt -s histappend
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

# Fuzzy find ------------------------------------------------------------------
#if command -v fzy >/dev/null 2>&1; then
    set -o vi #readline is not loaded yet or whatever
    function fzy-history {
        fc -lnr 1 \
            | sed 's/^[ \t]*//' \
            | awk '!seen[$0]++' \
            | fzy
    }

    if [[ ! -o vi ]]; then
        bind '"\er": redraw-current-line'
        bind '"\e^": history-expand-line'
        bind '"\C-r": " \C-e\C-u$(fzy-history||true)\e\C-e\e^\er\n"'
    else
        bind '"\C-x\C-a": vi-movement-mode'
        bind '"\C-x\C-e": shell-expand-line'
        bind '"\C-x\C-r": redraw-current-line'
        bind '"\C-x^": history-expand-line'
        bind '"\C-r": "\C-x\C-addi`fzy-history||true`\C-x\C-e\C-x^\C-x\C-a$a\C-x\C-r"'
        bind -m vi-command '"\C-r": "i\C-r"'
    fi
#fi

# Prompt definition -----------------------------------------------------------
BOLD=$'\033[0;1m' #base01
INVIS=$'\033[0;30m'
RED=$'\033[1;31m'
NONE=$'\033[m'

configure_prompt() {
    local ROW COL

    IFS=\; read -sdR -p $'\E[6n' ROW COL
    PS1="$([ "$COL" -eq 1 ] && printf "\\\\r" || printf "\\\\n")$PROMPT_BASE"
    promptcol="$([ "$1" -eq 0 ] || echo "$RED")"
}

PROMPT_COMMAND='configure_prompt $?'
PROMPT_BASE='\[${BOLD}\]\u@\h\[${INVIS}\]:\[${BOLD}\]\W\[${promptcol}\]\$\[${NONE}\] '
shopt -s globstar nocaseglob cmdhist checkwinsize autocd dirspell cdspell 2>/dev/null
# Don't record some commands
HISTTIMEFORMAT='%F %T '

