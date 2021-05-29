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

daemon() (exec "$@" >/dev/null 2>&1 &)
alias deluge='(deluge >/dev/null 2>&1 &)'
alias df='df -h'
alias du='du -h'
alias e='$EDITOR'
alias free='free -m | sed "s/\([a-z]\{4\}\)[^ ]*/\1/g;1s/^/./" | column -t'
alias ikhal='ikhal() { tput smcup; khal interactive "$@"; tput rmcup; }; ikhal'
alias o='gpg_unlock; printf "\e]0;chat\a"; matrix_client'
alias u='gpg_unlock; mail_client'
alias pass='gpg_unlock; pass'
alias pdflatex='pdflatex -interaction=batchmode'
alias psa='ps -Aopid,args | { if [ -t 1 ]; then less -F; else cat; fi; }'
alias pip='pip3'
alias please='sudo $(fc -ln -1)'
alias python='python3'
alias rsync="rsync -a$([ "$OS" = Darwin ] || echo z)hPS"
alias startx='startx "$XINITRC"'
alias sub='subliminal download -l en'
alias unflac='unflac -n \
    "{{printf .Input.TrackNumberFmt .Track.Number}} {{.Track.Title}}"'
alias valgrind='valgrind -q'
alias vid='mpv'

# SSH/GPG ---------------------------------------------------------------------
export GPG_TTY="$(tty)"

# Scripts ---------------------------------------------------------------------
git_promptline() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
         && {
            git rev-list --walk-reflogs --count refs/stash 2>/dev/null ||echo 0
            git status --porcelain --branch 2>/dev/null
         } | awk '
            NR == 1 { stashes = $0 }
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
