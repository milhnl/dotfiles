# sh/rc.sh - startup for POSIX shells
# Aliases ---------------------------------------------------------------------
if which exa >/dev/null 2>/dev/null; then
    alias ls='exa --group-directories-first --icons'
    alias lsf='ls --time-style=long-iso -lbg'
    alias lsa='ls --time-style=long-iso -lbga'
elif ls --version 2>/dev/null | grep -q GNU 2>/dev/null; then
    alias ls='ls --group-directories-first --color=auto -N'
    alias lsf='ls --time-style=long-iso -hl'
    alias lsa='lsf -a'
elif [ "$(uname -s)" = Darwin ]; then
    alias ls='ls -G'
    alias lsf='ls -Gl'
    alias lsa='ls -Gla'
else
    alias lsf='ls -l'
    alias lsa='ls -la'
fi

if diff --help 2>&1 | grep -q '.*--color'; then
    alias diff='diff -u --color=auto'
fi

daemon() (exec "$@" >/dev/null 2>&1 &)
in_dir() ( cd "$1"; shift; "$@"; )
mcup() { tput smcup; "$@"; tput rmcup; }
alias dot='git -C "$PREFIX/dot"'
alias df='df -h'
alias du='du -h'
alias e='$EDITOR'
alias free='free -m | sed "s/\([a-z]\{4\}\)[^ ]*/\1/g;1s/^/./" | column -t'
alias ikhal='ikhal() { tput smcup; khal interactive "$@"; tput rmcup; }; ikhal'
alias make='make -s'
alias o='gpg_unlock; printf "\e]0;chat\a"; matrix_client'
alias u='gpg_unlock; mail_client'
alias pass='gpg_unlock; pass'
alias pdflatex='pdflatex -interaction=batchmode'
alias psa='ps -Aopid,args | { if [ -t 1 ]; then less -F; else cat; fi; }'
alias pip='pip3'
alias please='sudo $(fc -ln -1)'
alias python='python3'
#Hack for using old rsync escaping until zsh sorts its completion out
alias rsync="rsync -a$([ "$(uname -s)" = Darwin ] || echo z)hPS $(\
    rsync --version | grep -q '3.2.[4-9]' && printf '%s' --old-args) "
alias sncli='sncli_() (
        <"$XDG_CONFIG_HOME/sncli/snclirc" \
            sed "s|\\\$XDG_DATA_HOME|$XDG_DATA_HOME|" >"$XDG_DATA_HOME/snclirc"
        export SNCLIRC="$XDG_DATA_HOME/snclirc"
        if [ $# -eq 0 ]; then mcup sncli; else sncli "$@"; fi;
    ); sncli_'
alias startx='startx "$XINITRC"'
alias sub='subliminal download -l en'
alias tig='mkdir -p "$XDG_DATA_HOME/tig"; tig'
alias top='top_() { if [ $# -eq 0 ]; then mcup top; else top "$@"; fi; }; top_'
alias unflac='unflac -n \
    "{{printf .Input.TrackNumberFmt .Track.Number}} {{.Track.Title}}"'
alias valgrind='valgrind -q'
alias vid='mpv'

# SSH/GPG ---------------------------------------------------------------------
export GPG_TTY="$(tty)"
if [ "$(ls -ld "$HOME" | sed 's/ .*//')" = drwxrwxrwx ]; then
    printf 'SOMETHING MESSED UP YOUR $HOME PERMISSIONS\n' >&2
    \ls -ld "$HOME" >&2
    sudo chmod og-rwx "$HOME"
    sudo chown "$(whoami):$(whoami)" "$HOME"
fi

# Scripts ---------------------------------------------------------------------
git_promptline() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
         && {
            git rev-list --walk-reflogs --count refs/stash 2>/dev/null ||echo 0
            git status --porcelain --branch 2>/dev/null
         } | awk '
            NR == 1 { stashes = $0 }
            /^## / {
                b = substr($0, 4)
                if (index(b, "No commits yet on ") == 1)
                    b = substr(b, 19)
                else if (index(b, "Initial commit on ") == 1)
                    b = substr(b, 19)
                else if (index(b, "HEAD (no branch)") == 1)
                    b = "HEAD"
                remotesplit = index(b, "...")
                if (remotesplit) {
                    branch = substr(b, 1, remotesplit - 1)
                    b = substr(b, remotesplit + 3)
                    remoteend = match(b, " [((ahead|behind) [0-9]*|, ){1,3}]$")
                    if (remoteend) {
                        remote = substr(b, 1, remoteend - 1)
                        b = substr(b, remoteend + 2, length(b) - remoteend - 2)
                        n = split(b, x, ", ")
                        for (i = 1; i <= n; i++) {
                            split(x[i], y, " ")
                            rs[y[1]] = y[2]
                        }
                        behind = rs["behind"]; ahead = rs["ahead"]
                    } else { remote = b }
                } else { branch = b }
                next
            }
            /^.[MD] / { unstaged += 1 }
            /^[^ ?]. / { staged += 1 }
            /^\?\? / { untracked += 1 }
            /^(.U|U.|AA|DD) / { state = "|merge" }
            END {
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
