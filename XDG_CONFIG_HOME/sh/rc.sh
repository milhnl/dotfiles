# sh/rc.sh - startup for POSIX shells
# Aliases ---------------------------------------------------------------------
if which exa >/dev/null 2>/dev/null; then
    alias ls='exa --group-directories-first'
    alias lsf='exa --group-directories-first --time-style=long-iso -lbg'
    alias lsa='exa --group-directories-first --time-style=long-iso -lbga'
elif ls --version 2>/dev/null | grep -q GNU 2>/dev/null; then
    alias ls='ls --group-directories-first --color=auto -N'
    alias lsf='ls --time-style=long-iso -hl'
    alias lsa='lsf -a'
elif [ "$OS" = Darwin ]; then
    alias ls='ls -G'
    alias lsf='ls -Gl'
    alias lsa='ls -Gla'
else
    alias lsf='ls -l'
    alias lsa='ls -la'
fi

alias df='df -h'
alias pdflatex='pdflatex -interaction=batchmode'
alias please='sudo $(fc -ln -1)'
alias rsync='rsync -azhPS'
alias startx='startx "$XINITRC"'
alias valgrind='valgrind -q'

# SSH -------------------------------------------------------------------------
command -v gpg-connect-agent >/dev/null 2>&1 \
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

realpath() {
    if ! command realpath >/dev/null 2>/dev/null; then
        [ -e "$1" ] && printf "%s/%s"\
            "$(cd "$(dirname "$(eval echo \"$1\")")"; pwd)" \
            "$(basename "$1")"
    else
        command realpath "$@"
    fi
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
    ("$(wslpath -u "$(vswhere.exe -property productPath|tr -d \\r)")" "$@" \
        >/dev/null 2>&1 &)
}

rider() {
    (cmd.exe /c "rider '$1' '$2'" >/dev/null 2>&1 &)
}

e() {
    if ! expr "$EDITOR" : vis >/dev/null 2>&1; then
        exists pacman && sudo pacman --needed --noconfirm -qS vis
        exists apk && sudo apk -q add vis
        exists brew && brew install vis
        if [ "$(uname -s)" = Darwin ] && exists vise; then
            export EDITOR=vise
        elif exists vis; then
            export EDITOR=vis
        fi
    fi
    case "$1" in 
    *.cs|*.cshtml)
        if tasklist.exe 2>/dev/null | grep -q devenv.exe; then
            devenv /edit "$(wslpath -w "$1")"
        elif cmd.exe /c 'where rider' >/dev/null 2>&1; then
            rider "$(upwardfind "$1" '*.sln')" "$(wslpath -w "$1")"
        elif command -v vswhere.exe >/dev/null 2&1; then
            devenv "$(wslpath -w "$(upwardfind "$1" '*.sln')")"
        else
            ewrap0 "$@"
        fi
        ;;
    *.sln|*.csproj)
        if tasklist.exe 2>/dev/null | grep -q devenv; then
            devenv "$(wslpath -w "$1")"
        elif cmd.exe /c 'where rider' >/dev/null 2>&1; then
            rider "$(wslpath -w "$1")"
        elif command -v vswhere.exe >/dev/null 2>&1; then
            devenv "$(wslpath -w "$1")"
        else
            ewrap0 "$@"
        fi
        ;;
    *) ewrap0 "$@" ;;
    esac
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

# Auto-installers -------------------------------------------------------------
exists() { command -v "$1" | grep -qF / >/dev/null 2>&1; }

if ! exists fzy; then
    fzy() {
        command -v apk >/dev/null 2>&1 && sudo apk add gcc musl-dev >&2
        currentdir="$PWD"
        workingdir="$(mktemp -d)"
        cd "$workingdir"
        git clone https://github.com/jhawthorn/fzy.git
        cd fzy
        make PREFIX="$PREFIX" install >&2
        cd "$currentdir"
        rm -rf "$workingdir"
        unset -f fzy; fzy "$@"
    }
fi

if ! exists judo; then
    judo() {
        go get github.com/rollcat/judo
        unset -f judo; judo "$@"
    }
fi

if ! exists mpv; then
    mpv() {
        if [ "$(uname -s)" = Darwin ]; then brew cask install mpv; fi
        if exists pacman; then sudo pacman --noconfirm --needed -qS mpv; fi
        unset -f mpv; mpv "$@"
    }
fi

if ! exists pacaur; then
    pacaur() {
        currentdir="$PWD"
        workingdir="$(mktemp -d)"
        cd "$workingdir"
        pacman -q -S --noconfirm --needed --asdeps \
                meson gmock gtest expac jq git \
            && git clone "https://aur.archlinux.org/auracle-git.git"\
            && (cd auracle-git && makepkg -i) \
            && git clone "https://aur.archlinux.org/pacaur.git" \
            && (cd pacaur && makepkg -i)
        cd "$currentdir";
        rm -rf "$workingdir"
        unset -f pacaur; pacaur "$@"
    }
fi

if ! exists pip; then
    pip() {
        curl https://bootstrap.pypa.io/get-pip.py | python - --user
        unset -f pip; pip "$@"
    }
fi

if ! exists rg; then
    rg() {
        curl -sLo "$XDG_CACHE_HOME/ripgrep.tar.gz" "$(\
            curl -s "$(printf '%s%s' "https://api.github.com/repos/" \
                    "BurntSushi/ripgrep/releases/latest")" \
                | sed -n '/browser_download_url/s/.*: "\(.*\)"/\1/p' \
                | grep -F "$(uname -m)-$(uname -s | sed -e \
                    's/Linux/unknown-linux-musl/;s/Darwin/apple-darwin/')")" \
            && mkdir -p "$XDG_CACHE_HOME/ripgrep" \
            && (cd "$XDG_CACHE_HOME/ripgrep"; tar -xzf ../ripgrep.tar.gz) \
            && cp "$XDG_CACHE_HOME/ripgrep/"*/rg "$XDG_BIN_HOME" \
            && mkdir -p "$XDG_DATA_HOME/man/man1" \
            && cp "$XDG_CACHE_HOME/ripgrep/"*/doc/rg.1 \
                "$XDG_DATA_HOME/man/man1" \
            && rm -rf "$XDG_CACHE_HOME/ripgrep.tar.gz" \
                "$XDG_CACHE_HOME/ripgrep"
        unset -f rg; rg "$@"
    }
fi

if ! exists rupm; then
    rupm() {
        curl https://raw.githubusercontent.com/milhnl/rupm/master/rupm.sh \
            | RUPM_MIRRORLIST="ssh://mil@milh.nl:.rupm/" sh /dev/stdin -yS rupm
        unset -f rupm; rupm "$@"
    }
fi

if ! exists tig; then
    tig() {
        if exists apk; then sudo apk -q add tig; fi
        if exists pacman; then sudo pacman --noconfirm --needed -qS tig; fi
        [ $# -eq 0 ] && set -- --branches --remotes --tags
        unset -f tig; tig "$@"
    }
fi

if ! exists usql; then
    usql() {
        go get -u github.com/xo/usql
        unset -f usql; usql "$@"
    }
fi
