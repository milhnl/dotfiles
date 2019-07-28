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
if [[ -f "$PREFIX/lib/fzy.bash" ]]; then
    set -o vi #readline is not loaded yet or whatever
    . "$PREFIX/lib/fzy.bash"
fi

# Prompt definition -----------------------------------------------------------
BOLD=$'\033[0;1m' #base01
INVIS=$'\033[0;30m'
RED=$'\033[1;31m'
NONE=$'\033[m'

configure_prompt() {
#    es=$?
    declare ROW
    declare COL

    if [[ "$es" -eq 0 ]]; then
        promptcol=''
    else
        promptcol="${RED}"
    fi
    IFS=';' read -sdR -p $'\E[6n' ROW COL
    if [ "$COL" -eq 1 ]; then
        PS1="\r$PROMPT_BASE"
    else
        PS1="\n$PROMPT_BASE"
    fi
}


PROMPT_COMMAND='es=$?;configure_prompt'
PROMPT_BASE='\[${BOLD}\][\u@\h\[${INVIS}\]:\[${BOLD}\]\W]\[${promptcol}\]\$\[${NONE}\] '

shopt -s globstar nocaseglob cmdhist checkwinsize autocd dirspell cdspell 2>/dev/null
# Don't record some commands
HISTTIMEFORMAT='%F %T '

