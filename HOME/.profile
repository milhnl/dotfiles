#.profile - {a,}sh startup file

PATH="$XDG_BIN_HOME:$PATH" #Fix for Alpine (?) resetting PATH
[[ -n "$OS" ]] || . "${XDG_CONFIG_HOME:-$HOME/.config}/sh/profile.sh"
[[ -f "$XDG_CONFIG_HOME/sh/rc.sh" ]] && . "$XDG_CONFIG_HOME/sh/rc.sh"

# Prompt definition -----------------------------------------------------------
BOLD=$'\033[0;1m'
INVIS=$'\033[0;30m'
NONE=$'\033[m'

PS1='\[${BOLD}\]\u@\h\[${INVIS}\]:\[${BOLD}\]\W\$\[${NONE}\] '
