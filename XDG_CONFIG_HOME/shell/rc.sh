# shell/rc.sh - startup for POSIX shells
# Aliases ---------------------------------------------------------------------
if which exa >/dev/null 2>/dev/null; then
    alias ls='exa --group-directories-first'
    alias lsf='exa --time-style=long-iso --group-directories-first -lbg'
    alias lsa='exa --time-style=long-iso --group-directories-first -lbga'
elif [ "$OS" = Darwin ]; then
    alias ls='ls -G'
    alias lsf='ls -Gl'
    alias lsa='ls -Gla'
else
    alias ls='ls --color=auto --group-directories-first -h'
    alias lsf='ls --color=auto --group-directories-first -h --full'
    alias lsa='ls -a --color=auto --group-directories-first -h --full'
fi

alias apt='sudo apt'
alias dnf='sudo dnf'
alias mutt="mutt -F \"$XDG_CONFIG_HOME/mutt/muttrc\""
alias pacman='sudo pacman'
alias pdflatex='pdflatex -interaction=batchmode'
alias please='sudo $(fc -ln -1)'
alias rc='rc -l'
alias rpm='sudo rpm'
alias startx='startx "$XINITRC"'
alias systemctl='sudo systemctl'
alias valgrind='valgrind -q'
alias wpa_cli='sudo wpa_cli'
alias wifi-menu='sudo wifi-menu'

# SSH -------------------------------------------------------------------------
[ -d "$HOME/.ssh" ] \
    && gpg-connect-agent updatestartuptty /bye >/dev/null 2>/dev/null \
    && export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"

# OS-specific settings --------------------------------------------------------
if [ "$DISTRO" = "Ubuntu" ]; then
    if [ "$DISTROVER" = "14.04" ]; then
        alias v="TERM=$TERM $EDITOR"
        alias ssh="TERM=$TERM ssh"
        alias git="TERM=$TERM git"
        export TERM="xterm"

        # Work around ssh not adding keys automagically
        ssh() {
            key="$(
                /usr/bin/ssh "$@" -vo BatchMode=yes true 2>&1 | awk '
                    /^debug1: Offering / { key = $NF }
                    /^debug1: Server accepts key/ { print key }
                ' | tr -cd '\40-\176'
            )"
            [ -n "$key" ] && ssh-add -L | grep -q "$(cut -d' ' -f2 <$key.pub)"\
                || ssh-add $key
            /usr/bin/ssh "$@"
        }
    fi
    [ -n "$SSH_AUTH_SOCK" ] \
        && export SSH_AUTH_SOCK="$(gpgconf --list-dirs \
            | sed -n 's/^agent-socket:\(.*\)/\1.ssh/p')"
fi

# Scripts ---------------------------------------------------------------------
git_promptline() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
         && git status --porcelain --branch 2>/dev/null | awk '
            /^## HEAD/ { branch = "(detached)" }
            /^## Initial commit on master$/ { branch = "master" }
            /^## / {
                remotesplit = index($2, "...")
                if (remotesplit) {
                    branch = substr($2, 1, remotesplit - 1)
                    remote = substr($2, remotesplit + 3)
                } else { branch = $2}
                $1 = $2 = ""
                n = split($0, x, ",")
                for (i = 1; i <= n; i++) {
                    split(x[i], y, " ")
                    rs[substr(y[1], (i - 3) * -1)] = \
                        substr(y[2], 1, length(y[2]) - (i == n ? 1 : 0))
                }
                behind = rs["behind"]; ahead = rs["ahead"]
            }
            /^.[MD]/ { unstaged += 1 }
            /^[^ ?]./ { staged += 1 }
            /^\?/ { untracked += 1 }
            /^(.U|U.|AA|DD) / { state = "|merge" }
            END {
                cmd = "git log -g --first-parent -m --oneline "
                cmd = cmd "--format=%gd -- refs/stash 2>/dev/null |wc -l"
                cmd | getline stashes
                close(cmd)
                if (remote != "") {
                    if (substr(remote, index(remote, "/") + 1) == branch) {
                        remote = (ahead + behind == 0) ? ":" : ""
                    } else { remote = ":" remote }
                }
                untracked = untracked > 0 ? "?" : ""
                unstaged = unstaged > 0 ? "*" : ""
                staged = staged > 0 ? "+" : ""
                behind = behind > 0 ? "↓" behind : ""
                ahead = ahead > 0 ? "↑" ahead : ""
                stashes = stashes > 0 ? "~" stashes : ""
                printf("%s%s%s", untracked, unstaged, staged)
                printf(" (%s%s%s%s%s%s)", branch, remote, behind, ahead, \
                    stashes, state)
            }' 2>/dev/null
}

free() {
    command free -hw "$@" | sed 's/total/. &/;/Swap: *0B *0B *0B/d' | column -t;
}

rmrfhome() {
    printf "Completely delete $HOME? "; read
    [ "$REPLY" = y ] || [ "$REPLY" = Y ] || return 1;
    find "$HOME" -mindepth 1 -not -path "$HOME/.ssh*" -delete
}

gpgunlock() {
    gpg -da "$GNUPGHOME/empty.asc" >/dev/null 2>/dev/null
}

mkmy() {
    [ "$#" -eq 0 ] && set -- install
    env -i \
        PREFIX="$PREFIX" \
        prefix="$PREFIX" \
        PATH="$PATH" \
        HOME="$HOME" \
        TERM="$TERM" \
        TERMINFO="$TERMINFO" \
        CC="${CC:-cc}" \
        WITH_BASHCOMP="yes" `#For pass` \
        make --environment-overrides "$@"
}

rg() {
    if command rg --version >/dev/null 2>&1; then
        command rg "$@"
    elif grep --colour=auto . /dev/null >/dev/null 2>&1; [ $? != 2 ]; then
        grep --colour=auto -r "$1" .
    else
        grep -r "$1" .
    fi
}

pacaur() {
    if ! command pacaur -h >/dev/null 2>/dev/null; then (
        workingdir="$(mktemp -d)"
        cd "$workingdir"
        pacman -S expac yajl git --noconfirm --needed \
            && (
                if [ "$(uname -m)" = armv6l ]; then
                    pacman -S cower
                else
                    git clone "https://aur.archlinux.org/cower.git" \
                    && cd cower && makepkg -i && cd ..
                fi
            ) \
            && git clone "https://aur.archlinux.org/pacaur.git" \
            && cd pacaur && makepkg -i && cd ..
        cd; rm -rf "$workingdir"
    ); fi
    command pacaur "$@"
}

pip() {
    if ! command pip >/dev/null 2>&1; then
        curl https://bootstrap.pypa.io/get-pip.py | python - --user
    else
        command pip "$@"
    fi
}

realpath() {
    if ! command realpath >/dev/null 2>/dev/null; then
        [ -e "$1" ] && printf "%s/%s"\
            "$(cd "$(dirname "$(eval echo \"$1\")")"; pwd)" \
            "$(basename "$1")"
    else
        command realpath "$@"
    fi
}

winenvdir() {
    wslpath -u "$(cmd.exe /c "echo %$1%"| sed 's/\r//')"
}

upwardfind() { #1: path, #2: glob
    (
        set -- "$(dirname "$(realpath "$1")")" "$2"
        cd "$1" >/dev/null 2>&1 || return 1 #base case /
        set -- "$1" "$2" "$(find . -maxdepth 1 -name "$2")"
        test -e "$3" && printf "%s" "$PWD/$3" || upwardfind "$1" "$2"
    )
}

ewrap1() {
	if test -e "$1" && ! test -w "$1"; then
		sudo vi "$@"
	else
		"$EDITOR" "$@"
	fi
}

ewrap0() {
    [ "$1" = -- ] && shift
    if test -f "$1" && grep -q "$(printf '\357\273\277')" "$1"; then
        sed -e "$(printf 's/\r$//; 1s/^\xef\xbb\xbf//')" -i "$@"
        ewrap1 "$1"
        sed -e "$(printf '1s/^/\xef\xbb\xbf/')" -i "$@"
    else
        ewrap1 "$@"
    fi
}

e() {
    if test -n "$ZSH_VERSION"; then
        ISHELL=zsh
    elif test -n "$BASH_VERSION"; then
        ISHELL=bash
    else
        ISHELL=sh
    fi
    case "$1" in 
    alacritty) grep -iq microsoft /proc/version 2>/dev/null \
        && ewrap0 "$(winenvdir APPDATA)/alacritty/alacritty.yml" \
        || ewrap0 "$XDG_CONFIG_HOME/alacritty/alacritty.yml" ;;
    ansible) ewrap0 "$ANSIBLE_CONFIG" ;;
    bash) ewrap0 "$HOME/.bashrc"; [ $ISHELL = bash ] && exec bash; true;;
    env) ewrap0 "$XDG_CONFIG_HOME/environment.d/00-base.conf" \
        && exec "${ISHELL}" ;;
    firefox) ewrap0 "$XDG_CONFIG_HOME/firefox/user.js" ;;
    gpg) ewrap0 "$GNUPGHOME/gpg.conf" ;;
    gpg-agent) ewrap0 "$GNUPGHOME/gpg-agent.conf" ;;
    history) ewrap0 "$XDG_DATA_HOME/$ISHELL/history" ;;
    mbsync|isync) ewrap0 "$XDG_CONFIG_HOME/isync/mbsyncrc" ;;
    msmtp) ewrap0 "$XDG_CONFIG_HOME/msmtp/msmtprc" ;;
    mutt) ewrap0 "$XDG_CONFIG_HOME/mutt/muttrc" ;;
    mutt-*) ewrap0 "$XDG_CONFIG_HOME/mutt/accounts/${1#mutt-}" ;;
    pam) ewrap0 "$HOME/.pam_environment"; echo "warning: relogin required";;
    profile) ewrap0 "$XDG_CONFIG_HOME/shell/profile.sh"; exec "${ISHELL}" ;;
    rc) ewrap0 "$XDG_CONFIG_HOME/shell/rc.sh"; exec "${ISHELL}" ;;
    setup) ewrap0 "$XDG_CONFIG_HOME/shell/setup.sh" ;;
    sh) ewrap0 "$HOME/.profile"; [ $ISHELL = sh ] && exec sh; true ;;
    sway) ewrap0 "$XDG_CONFIG_HOME/sway/config" ;;
    vis) ewrap0 "$XDG_CONFIG_HOME/vis/visrc.lua" ;;
    vis-theme) ewrap0 "$XDG_CONFIG_HOME/vis/themes/default.lua" ;;
    vim) ewrap0 "$XDG_CONFIG_HOME/vim/vimrc" ;;
    x11) ewrap0 "$XDG_CONFIG_HOME/X11/xinitrc" ;;
    zsh) ewrap0 "$ZDOTDIR/.zshrc"; [ $ISHELL = zsh ] && exec zsh; true;;
    *.cs|*.cshtml)
        if tasklist.exe 2>/dev/null | grep -q devenv.exe; then
            devenv.exe /edit "$(wslpath -w "$1")" >/dev/null 2>&1 &
        elif cmd.exe /c 'where rider' >/dev/null 2>&1; then
            cmd.exe /c "rider '$(wslpath -w "$(upwardfind "$1" '*.sln')")' \
                '$(wslpath -w "$1")'" >/dev/null 2>&1 &
        elif command -v devenv.exe >/dev/null 2&1; then
            devenv.exe "$(wslpath -w "$(upwardfind "$1" '*.sln')")" \
                >/dev/null 2>&1 &
        else
            ewrap0 "$@"
        fi
        ;;
    *.sln|*.csproj)
        if tasklist.exe 2>/dev/null | grep -q devenv.exe; then
            devenv.exe "$(wslpath -w "$1")" >/dev/null 2>&1 &
        elif cmd.exe /c 'where rider' >/dev/null 2>&1; then
            cmd.exe /c "rider '$(wslpath -w "$1")'" >/dev/null 2>&1 &
        elif command -v devenv.exe >/dev/null 2>&1; then
            devenv.exe "$(wslpath -w "$1")" >/dev/null 2>&1 &
        else
            ewrap0 "$@"
        fi
        ;;
    *) ewrap0 "$@" ;;
    esac
}

play() {
    mpdlist \
        | shuf \
        | fzy \
        | sed 's/ - /\t/' \
        | IFS='	' read artist title &&mpc find artist "$artist" title "$title"\
        | mpc add && mpc play >/dev/null
}

wallpaper() {
    case "$OS" in
    Darwin)
        sqlite3 ~/Library/Application\ Support/Dock/desktoppicture.db \
            "update data set value = '$1'"
        osascript -e "$(printf '%s "%s"' \
            'tell application "Finder" to set desktop picture to POSIX file' \
            "$(realpath "$1")")"
        killall Dock
        ;;
    Linux)
        if [ "$XDG_SESSION_DESKTOP" = gnome ] \
                || [ "$XDG_SESSION_DESKTOP" = gnome-xorg ]; then
            gsettings set org.gnome.desktop.background picture-uri \
                "file://$(realpath "$1")"
            gsettings set org.gnome.desktop.background picture-options zoom
        elif grep -iq microsoft /proc/version 2>/dev/null; then
            set -- "$1" "$(cmd.exe /c 'echo %USERPROFILE%')/$(basename "$1")"
            set -- "$1" "$(echo "$2" | sed 's/\r//')"
            cp "$1" "$(wslpath -u "$2")"
            reg.exe add "HKCU\Control Panel\Desktop" /f /v Wallpaper /d "$2"
            rundll32.exe user32.dll, UpdatePerUserSystemParameters
        fi
        ;;
    *) printf "Not supported\n" ;;
    esac
}

routerip() {
    case "$OS" in
    Linux) ip route | awk '/default/ { print $3 }' ;;
    Darwin) route -n get default | awk '/gateway/ { print $2 }' ;;
    esac
}

sshremovekey() {
    sed -e "$1"d -if "$HOME/.ssh/known_hosts"
}

colors() {
    T='gYw'   # The test text

    echo -e "\n                 40m     41m     42m     43m\
    44m     45m     46m     47m";

    for FGs in '    m' '   1m' '  30m' '1;30m' '  31m' '1;31m' '  32m' \
            '1;32m' '  33m' '1;33m' '  34m' '1;34m' '  35m' '1;35m' \
            '  36m' '1;36m' '  37m' '1;37m'; do
        FG=${FGs// /}
        echo -en " $FGs \033[$FG  $T  "
        for BG in 40m 41m 42m 43m 44m 45m 46m 47m; do
            echo -en "$EINS \033[$FG\033[$BG  $T  \033[0m";
        done
        echo
    done
    echo
}

