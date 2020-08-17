FPATH="$XDG_DATA_HOME/zsh/site-functions:$FPATH"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$( \
    [ $(uname -s) = Darwin ] \
        && echo "$HOME/Library/Application Support" \
        || echo "$HOME/.config" \
    )}"
ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
