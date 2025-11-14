# sh/profile.sh - session for POSIX shells
# shellcheck disable=SC2034,SC2155
append_path() {
    case "$PATH" in
    "$1" | *":$1" | *":$1:"*) true ;;
    *) PATH="${PATH+$PATH:}$1" ;;
    esac
}

for x in /etc/profile.d/*.sh "$XDG_CONFIG_HOME/profile.d"/*.sh; do
    [ -e "$x" ] || continue
    # shellcheck source=/dev/null
    echo "$x" | grep -Eq jre\|perl\|raspberry || . "$x"
done

# ENVIRONMENT -----------------------------------------------------------------
#XDG vars are the scaffold for the other ones, and quite important.
#Set them to their default values here
set -a
if [ "$(uname -s)" = Darwin ]; then
    XDG_CONFIG_HOME="${XDG_CONFIG_HOME-$HOME/Library/Application Support}"
    XDG_CACHE_HOME="${XDG_CACHE_HOME-$HOME/Library/Caches}"
    MACOS_LIBRARY="${MACOS_LIBRARY-$HOME/Library}"
    PREFIX="${PREFIX-$HOME/Library/Local}"
    eval "$(locale)"
else
    XDG_CONFIG_HOME="${XDG_CONFIG_HOME-$HOME/.config}"
    XDG_CACHE_HOME="${XDG_CACHE_HOME-$HOME/.cache}"
    PREFIX="${PREFIX-$HOME/.local}"
fi
XDG_BIN_HOME="${XDG_BIN_HOME-$PREFIX/bin}"
XDG_DATA_HOME="${XDG_DATA_HOME-$PREFIX/share}"
XDG_STATE_HOME="${XDG_DATA_HOME-$PREFIX/state}"
PATH="$XDG_BIN_HOME:$PATH"
# shellcheck source=../environment.d/10-applications.conf
. "$XDG_CONFIG_HOME/environment.d/10-applications.conf"
while read -r LINE; do
    printenv "${LINE%%=*}" >/dev/null 2>&1 || eval "$LINE"
done <"$XDG_CONFIG_HOME/user-dirs.dirs"
if command -v python3 >/dev/null 2>&1; then
    append_path "$(python3 -m site --user-base)/bin"
fi
append_path "$XDG_DATA_HOME/npm/bin"
append_path "$XDG_DATA_HOME/cargo/bin"
append_path "$GOPATH/bin"
append_path "$PREFIX/lib/sh/polyfill/$(uname -s)"
append_path "$HOME/.dotnet/tools"
set +a

# OS-specific options ---------------------------------------------------------
# dotnet in PATH for Fedora
[ -d "/usr/share/dotnet" ] && append_path "/usr/share/dotnet"

# XDG_RUNTIME_DIR for WSL and pmOS ssh
if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    if [ ! -d "$XDG_RUNTIME_DIR" ]; then
        export XDG_RUNTIME_DIR="$XDG_CACHE_HOME/xdgrun"
        if [ ! -d "$XDG_RUNTIME_DIR" ]; then
            mkdir -p "$XDG_RUNTIME_DIR"
            chmod go-rwx "$XDG_RUNTIME_DIR"
        fi
    fi
fi

if grep -iq microsoft /proc/version 2>/dev/null; then
    # Extend PATH for ssh to WSL
    append_path "$(
        cd /mnt/c || return
        ./Windows/System32/cmd.exe /c 'echo %PATH%' \
            | tr ';' '\n' \
            | grep . \
            | (
                while IFS= read -r REPLY \
                    && [ -n "$(echo "$REPLY" | tr -d '[:space:]')" ]; do
                    wslpath -u "$REPLY"
                done
            ) \
            | tr '\n' ':'
    )"
    ! "${WSL_OWNER-false}" || export WORKSPACE_REPO_HOME="$(
        wslpath -u "$(powershell.exe -NoProfile -c '
            [Environment]::GetEnvironmentVariable("WORKSPACE_REPO_HOME")
        ' | sed s/\\r\$//)"
    )"
elif [ "$(uname -s)" = Darwin ]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
    export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
    export HOMEBREW_REPOSITORY="/opt/homebrew"
    export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
    export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
    append_path "/opt/homebrew/bin:/opt/homebrew/sbin"
fi

append_path "$PREFIX/lib/sh/lazyload"

if command -v fzf 2>/dev/null | grep -qv /lazyload/ \
    && fzf --help | grep -q .--pointer; then
    FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --pointer=' '"
fi

# SSH/GPG ---------------------------------------------------------------------
(
    set -- gnome3 mac curses
    until command -v "pinentry-$1"; do
        shift
        [ $# -gt 0 ] || break
    done
) 2>/dev/null \
    | sed 's/^/pinentry-program /' \
    | cat "$GNUPGHOME/gpg-agent-base.conf" - \
        >"$GNUPGHOME/gpg-agent.conf" 2>/dev/null

# Set-up ----------------------------------------------------------------------
mergehistory() {
    set -- "$1" "$2" "$(mktemp)"
    mkdir -p "$(dirname "$2")"
    cat "$1" "$2" >"$3" 2>/dev/null
    mv "$3" "$2"
    rm "$1"
}

[ -f "$HOME/.bash_history" ] \
    && (mergehistory "$HOME/.bash_history" "$XDG_DATA_HOME/bash/history" &)
[ -f "$HOME/.zsh_history" ] \
    && (mergehistory "$HOME/.zsh_history" "$XDG_DATA_HOME/zsh/history" &)

# Start X ---------------------------------------------------------------------
[ -n "${ALACRITTY_SOCKET-}" ] \
    || export ALACRITTY_SOCKET="$XDG_RUNTIME_DIR/alacritty-$RANDOM.sock"
[ -n "$DISPLAY" ] \
    || [ "0$(fgconsole 2>/dev/null || echo 0)" -ne 1 ] \
    || [ "$(tty)" != '/dev/tty1' ] \
    || WLR_LIBINPUT_NO_DEVICES=1 FROMPROFILE=true sway
