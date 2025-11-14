# sh/rc.sh - startup for POSIX shells
# shellcheck disable=SC2262,SC2010,SC2012,SC2155,SC2016
# Aliases ---------------------------------------------------------------------
if command -v eza >/dev/null 2>/dev/null; then
    alias ls='eza --group-directories-first --icons=auto'
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
in_dir() (cd "$1" && shift && "$@")
mcup() { tput smcup && "$@" || : && tput rmcup; }
alias dot='git -C "${DOTFILES-$PREFIX/dot}"'
alias df='df -h'
alias du='du -h'
alias e='$EDITOR'
alias esphome='workspace in shadow in_dir XDG_CONFIG_HOME/esphome esphome'
alias ffmpeg='ffmpeg -hide_banner'
alias free='free -m | sed "s/\([a-z]\{4\}\)[^ ]*/\1/g;1s/^/./" | column -t'
alias ikhal='mcup khal interactive'
alias ip='ip --color=auto'
alias make='make -s'
alias o='gpg_unlock; printf "\e]0;chat\a"; matrix_client'
alias u='gpg_unlock; mail_client'
alias pass='gpg_unlock; pass'
alias pdflatex='pdflatex -interaction=batchmode'
psa() { ps -Aopid,args | if [ $# -gt 0 ]; then grep "$1"; else less -F; fi; }
#Hack for using old rsync escaping until zsh sorts its completion out
#Will probably be here until the end of time due to macOS rsync
rsync() {
    env RSYNC_OLD_ARGS=1 \
        rsync -a"$([ "$(uname -s)" = Darwin ] || echo z)"hPS "$@"
}
sncli() (
    <"$XDG_CONFIG_HOME/sncli/snclirc" sed \
        "s|\\\$XDG_DATA_HOME|$XDG_DATA_HOME|" >"$XDG_DATA_HOME/snclirc"
    export SNCLIRC="$XDG_DATA_HOME/snclirc"
    if [ $# -eq 0 ]; then mcup env sncli; else env sncli "$@"; fi
)
alias startx='startx "$XINITRC"'
alias tig='mkdir -p "$XDG_DATA_HOME/tig"; printf "\\e]0;tig\\a"; tig'
top() { if [ $# -eq 0 ]; then mcup env top; else env top "$@"; fi; }
alias unflac='unflac -n \
    "{{printf .Input.TrackNumberFmt .Track.Number}} {{.Track.Title}}"'
alias usql='usql -q'
alias valgrind='valgrind -q --leak-check=full'

# SSH/GPG ---------------------------------------------------------------------
export GPG_TTY="$(tty)"

case "${SSH_AUTH_SOCK-}" in
*gpg-agent*) ;;
*) ! command -v gpgconf >/dev/null 2>&1 \
    || export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)" ;;
esac

if [ "$(ls -ld "$HOME" | sed 's/ .*//')" = drwxrwxrwx ]; then
    printf 'SOMETHING MESSED UP YOUR $HOME PERMISSIONS\n' >&2
    \ls -ld "$HOME" >&2
    sudo chmod og-rwx "$HOME"
    sudo chown "$(whoami):$(whoami)" "$HOME"
fi

# Scripts ---------------------------------------------------------------------
git_promptline() {
    git status --porcelain=v2 --branch --show-stash 2>/dev/null | awk '
        /# stash / { stashes = substr($0, 9) }
        /# branch.head / { branch = substr($0, 15) }
        /# branch.upstream / {
            upstream = substr($0, 19)
            gone = ahead + behind == 0
        }
        /# branch.ab / {
            n = split(substr($0, 13), x, " ")
            gone = 0
            ahead = substr(x[1], 2)
            behind = substr(x[2], 2)
        }
        /^[12] .[MD] / { unstaged += 1 }
        /^[12] [^.?]. / { staged += 1 }
        /^\? / { untracked = 1 }
        /^u / { unmerged += 1 }
        END {
            if (NR == 0) exit
            if (branch == "(detached)") branch = "HEAD"
            if (upstream != "") {
                if (substr(upstream, index(upstream, "/") + 1) == branch) {
                    upstream = (ahead + behind == 0 && !gone) ? ":" : ""
                } else { upstream = ":" upstream }
            }
            unmerged = unmerged > 0 ? "!" : ""
            untracked = untracked > 0 ? "?" : ""
            unstaged = unstaged > 0 ? "*" : ""
            staged = staged > 0 ? "+" : ""
            behind = behind > 0 ? "↓" behind : ""
            ahead = ahead > 0 ? "↑" ahead : ""
            updates = gone ? "⇡" : (behind ahead)
            merging = unmerged ? "|merge" : ""
            stashes = stashes > 0 ? "~" stashes : ""
            printf("%s%s%s%s ", unmerged, untracked, unstaged, staged)
            printf("(%s%s%s%s)", branch, upstream, updates, merging)
            printf("%s", stashes)
        }'
}
