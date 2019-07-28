ZDOTDIR="${XDG_CONFIG_DIR:-$( \
    [ $(uname -s) = Darwin ] \
        && echo "$HOME/Library/Application Support" \
        || echo "$HOME/.config" \
    )}/zsh"
