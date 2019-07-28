# sh/rc.sh - startup for POSIX shells
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
alias df='df -h'
alias dnf='sudo dnf'
alias gpgunlock='gpg -da "$GNUPGHOME/empty.asc" >/dev/null 2>&1'
alias mutt="mutt -F \"$XDG_CONFIG_HOME/mutt/muttrc\""
alias pacman='sudo pacman'
alias pdflatex='pdflatex -interaction=batchmode'
alias please='sudo $(fc -ln -1)'
alias rc='rc -l'
alias rpm='sudo rpm'
alias rsync='rsync -azhPS'
alias startx='startx "$XINITRC"'
alias systemctl='sudo systemctl'
alias valgrind='valgrind -q'
alias wpa_cli='sudo wpa_cli'
alias wifi-menu='sudo wifi-menu'

# SSH -------------------------------------------------------------------------
[ -d "$HOME/.ssh" ] \
    && gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 \
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
                cmd = "git stash list | wc -l"
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
                printf("%s%s%s ", untracked, unstaged, staged)
                printf("(%s%s%s%s%s)", branch, remote, behind, ahead, state)
                printf("%s", stashes)
            }' 2>/dev/null
}

tig() {
    [ $# -eq 0 ] && set -- --branches --remotes --tags
    command tig "$@"
}

rmrfhome() {
    printf "Completely delete $HOME? "; read
    [ "$REPLY" = y ] || [ "$REPLY" = Y ] || return 1;
    find "$HOME" -mindepth 1 -not -path "$HOME/.ssh*" -delete
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

rgex() { #1: selector, 2: replacement
    [ $# -eq 2 ] || { printf "usage: rgex SELECTOR REPLACEMENT\n"; return 1; }
    rg -l "$1" | xargs -rn1 ex -sc "%s/$1/$2/|wq!"
}

rename() {
    subst="$1"; shift
    for x; do
        mv "$x" "$(echo "$x" | sed "$subst")" || return 1
    done
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

devenv() {
    "$(wslpath -u "$(vswhere.exe -property productPath|tr -d \\r)")" "$@"
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
    env) ewrap0 "$XDG_CONFIG_HOME/environment.d/10-applications.conf" \
        && exec "${ISHELL}" ;;
    firefox) ewrap0 "$XDG_CONFIG_HOME/firefox/user.js" ;;
    git) ewrap0 "$XDG_CONFIG_HOME/git/config" ;;
    gpg) ewrap0 "$GNUPGHOME/gpg.conf" ;;
    gpg-agent) ewrap0 "$GNUPGHOME/gpg-agent.conf" ;;
    history) ewrap0 "$XDG_DATA_HOME/$ISHELL/history" ;;
    mbsync|isync) ewrap0 "$XDG_CONFIG_HOME/isync/mbsyncrc" ;;
    msmtp) ewrap0 "$XDG_CONFIG_HOME/msmtp/msmtprc" ;;
    mutt) ewrap0 "$XDG_CONFIG_HOME/mutt/muttrc" ;;
    mutt-*) ewrap0 "$XDG_CONFIG_HOME/mutt/accounts/${1#mutt-}" ;;
    npm) ewrap0 "$XDG_CONFIG_HOME/npm/npmrc" ;;
    pam) ewrap0 "$HOME/.pam_environment"; echo "warning: relogin required";;
    profile) ewrap0 "$XDG_CONFIG_HOME/sh/profile.sh"; exec "${ISHELL}" ;;
    rc) ewrap0 "$XDG_CONFIG_HOME/sh/rc.sh"; exec "${ISHELL}" ;;
    setup) ewrap0 "$XDG_CONFIG_HOME/sh/setup.sh" ;;
    sh) ewrap0 "$HOME/.profile"; [ $ISHELL = sh ] && exec sh; true ;;
    ssh) ewrap0 "$HOME/.ssh/config" ;;
    sway) ewrap0 "$XDG_CONFIG_HOME/sway/config" ;;
    tig) ewrap0 "$XDG_CONFIG_HOME/tig/config" ;;
    vis) ewrap0 "$XDG_CONFIG_HOME/vis/visrc.lua" ;;
    vis-theme) ewrap0 "$XDG_CONFIG_HOME/vis/themes/default.lua" ;;
    vim) ewrap0 "$XDG_CONFIG_HOME/vim/vimrc" ;;
    x11) ewrap0 "$XDG_CONFIG_HOME/X11/xinitrc" ;;
    zsh) ewrap0 "$ZDOTDIR/.zshrc"; [ $ISHELL = zsh ] && exec zsh; true;;
    *.cs|*.cshtml)
        if tasklist.exe 2>/dev/null | grep -q devenv.exe; then
            devenv /edit "$(wslpath -w "$1")" >/dev/null 2>&1 &
        elif cmd.exe /c 'where rider' >/dev/null 2>&1; then
            cmd.exe /c "rider '$(wslpath -w "$(upwardfind "$1" '*.sln')")' \
                '$(wslpath -w "$1")'" >/dev/null 2>&1 &
        elif command -v vswhere.exe >/dev/null 2&1; then
            devenv "$(wslpath -w "$(upwardfind "$1" '*.sln')")" \
                >/dev/null 2>&1 &
        else
            ewrap0 "$@"
        fi
        ;;
    *.sln|*.csproj)
        if tasklist.exe 2>/dev/null | grep -q devenv; then
            devenv "$(wslpath -w "$1")" >/dev/null 2>&1 &
        elif cmd.exe /c 'where rider' >/dev/null 2>&1; then
            cmd.exe /c "rider '$(wslpath -w "$1")'" >/dev/null 2>&1 &
        elif command -v vswhere >/dev/null 2>&1; then
            devenv "$(wslpath -w "$1")" >/dev/null 2>&1 &
        else
            ewrap0 "$@"
        fi
        ;;
    *) ewrap0 "$@" ;;
    esac
}

ep() {
    set -- "$(rg --files|fzy)"
    [ -n "$1" ] && e "$1"
}

graph() {
    git log --graph --abbrev-commit --format=format:'%C(bold blue)%h%C(reset) %C(bold cyan)%ad%C(reset) %C(bold green)(%ar)%C(black) %aN %C(reset)%C(white)%<(50,trunc)%s#%C(auto)%+D%C(reset)' --branches --remotes --tags --date=short --color \
        | sed \
            -e 's/(\([0-9][0-9]*\) years, \([0-9][0-9]*\) months ago)/\1y\2m/'\
            -e 's/(1 year, 1 month ago)/1y1m/'\
            -e 's/(\([0-9][0-9]*\) years, 1 month ago)/\1y1m/'\
            -e 's/(1 year, \([0-9][0-9]*\) months ago)/1y\1m/'\
            -e 's/(\([0-9][0-9]*\) years ago)/\1y/' \
            -e 's/(1 year ago)/1y/' \
            -e 's/(\([0-9][0-9]*\) months ago)/\1M/' \
            -e 's/(\([0-9][0-9]*\) weeks ago)/\1w/' \
            -e 's/(\([0-9][0-9]*\) days ago)/\1d/' \
            -e 's/(\([0-9][0-9]*\) hours ago)/\1h/' \
            -e 's/(\([0-9][0-9]*\) minutes ago)/\1m/' \
            -e "s/Merge remote-tracking branch /Merge /" \
            -e 's/Merge branch/Merge/' \
            -e 's/\s*#//' \
        | less -r
            #-e "s/Merge '\([^']*\)'/Merge/" \
            #-e "s/Merge remote-tracking branch '\([^']*\)'/Merge \1/" \
}

play() {
    mpdlist \
        | shuf \
        | fzy \
        | sed 's/ - /\t/' \
        | IFS='	' read artist title &&mpc find artist "$artist" title "$title"\
        | mpc add && mpc play >/dev/null
}

sshremovekey() {
    sed -e "$1"d -if "$HOME/.ssh/known_hosts"
}

mksshkey() {
    [ "$#" -eq 1 ] || { echo "Usage: mksshkey SECURITY_REALM"; exit 1; }

    set -- "$1" "$(mktemp)" \
        "$(gpg --list-secret-keys \
            | sed -n 's/^uid.*\[ultimate\].*<\(.*\)>$/\1/p')"
    printf "addkey\n8\ns\ne\na\nq\n2048\n0\nsave\n" >"$2"
    LC_ALL= LANG=en gpg --set-notation comment_en@opengpg-notations.org="$1" \
        --expert --batch --command-file "$2" --edit-key "$3" 2>/dev/null
    rm "$2"
    gpg -K --with-keygrip | awk 'f{print $3;f=0} /\[A\]/{f=1}' \
        >"$GNUPGHOME/sshcontrol"
    gpg -K --with-sig-list --list-options show-notations --with-keygrip \
        --fingerprint --fingerprint | awk '
            /^ssb/ {
                authkey = 0;
                if (index($4, "A")) authkey = 1;
                getline;
                split($0, fp, " ");
                fingerprint = fp[1] fp[2] fp[3] fp[4] fp[5] fp[6] fp[7] fp[8] \
                    fp[9] fp[10];
                cmd = "gpg --export-ssh-key " fingerprint "|cut -d\\  -f1,2" ;
                cmd | getline pubkey;
            }
            /^sig/ { date = $4 }
            /Keygrip/ { grip = $3; }
            /Signature/ {
                comment = substr($0, index($0, "=") + 1);
                if (authkey) print pubkey, date, comment;
            }
        '\
        | grep "$1" >"$HOME/.ssh/$1.pub"
    gpg --export-secret-keys -a >"$GNUPGHOME/keys.asc"
}


vid() {
    mpv "$1"
}

resub() {
    command -v subliminal >/dev/null 2>&1 \
        && subliminal download -l en "$1"
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

rpi_img() {
    [ $# -ne 3 ] && { echo "usage: rpi_img path version size" >&2; return 1; }
    truncate -s "$3" "$1"
    set -- "$@" "$(losetup -fP --show "$1")"
    expr "$4" : /dev/ || { echo "loopback setup failed" >&2; return 1; }
    echo 'o; n;p;1;;+100M; t;c; n;p;2;;; w;q;' \
        | tr -d \  | tr ';' '\n' \
        | fdisk "$1"
    blockdev --rereadpt -v "$4"
    mkfs.vfat "${4}p1" && mkdir boot && mount "${4}p1" boot
    mkfs.ext4 "${4}p2" && mkdir root && mount "${4}p2" root
    [ -d boot ] && [ -d root ] || return 1
    wget "http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-${2}-latest.tar.gz"
    bsdtar -xpf "ArchLinuxARM-rpi-${2}-latest.tar.gz" -C root && sync
    mv root/boot/* boot && sync
    umount boot root && rmdir boot root && losetup -d "$4"
}

# Machine-specific options ----------------------------------------------------
if [ "$(hostname)" = iau ]; then
    PATH="$PATH:$XDG_DATA_HOME/npm/bin"
    (command -v iisexpress-proxy || npm add -g iisexpress-proxy)>/dev/null 2>&1
    ps -Ao args | grep -q iisexpress-proxy || \
        (nohup iisexpress-proxy 8080 to 8079 >/dev/null 2>&1 &)
    tunnel 8003:localhost:8079 milh.nl
    tunnel 3303:localhost:3389 milh.nl
    ps -o comm | grep -q sshd || sudo /usr/sbin/sshd
    tunnel 2203:localhost:22 milh.nl

    dotnet() {
        case "$1" in
        build)
            "$(wslpath -u "$(vswhere.exe -latest -requires \
                Microsoft.Component.MSBuild -find "MSBuild\**\Bin\MSBuild.exe"\
                )"|tr -d \\r)"
            ;;
        run)
            #/config:"$(wslpath -w ../.vs/config/applicationhost.config)" \
            #/systray
            /mnt/c/Program\ Files\ \(x86\)/IIS\ Express/iisexpress.exe \
                /path:"$(wslpath -w ..)"
            ;;
        ef)
            [ "$2 $3" = "database drop" ] || return 1
            rm "$(winenvdir USERPROFILE)/develop.mdf"
            rm "$(winenvdir USERPROFILE)/develop_log.ldf"
            SqlLocalDB.exe stop MSSQLLocalDB
            SqlLocalDB.exe delete MSSQLLocalDB
            ;;
        esac
    }
fi
