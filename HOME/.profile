#.profile - {a,}sh startup file

[[ -n "$OS" ]] || . "${XDG_CONFIG_HOME:-$HOME/.config}/shell/profile.sh"
[[ -f "$XDG_CONFIG_HOME/shell/rc.sh" ]] && . "$XDG_CONFIG_HOME/shell/rc.sh"

# Prompt definition -----------------------------------------------------------
BOLD=$'\033[0;1m' #base01
INVIS=$'\033[0;30m'
RED=$'\033[1;31m'
NONE=$'\033[m'

PS1='\[${BOLD}\][\u@\h\[${INVIS}\]:\[${BOLD}\]\W]\$\[${NONE}\] '
