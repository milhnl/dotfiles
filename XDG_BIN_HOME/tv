#!/usr/bin/env sh
#tv - watch series
set -eu

url_decode() {
    printf "$(printf "%s" "${1-$(cat)}" | sed 's/%/\\x/g')"
}

url_encode() { #1:string; 2:literal 3:format 4:args 5:tail 6:head 7:IFS
    set -- "${1-$(cat)}" "" "" "" "" "" #1: string
    while
        set -- "$1" "${1%%[!-._~0-9A-Za-z]*}" "$3" "$4" "$5" "$6"
        case "$2" in ?*) set -- "${1#$2}" "$2" "$3%s" "$4 $2" "$5" "$6";; esac
        case "$1" in "") false;; esac
    do
        set -- "$1" "$2" "$3" "$4" "${1#?}" "$6"
        set -- "$1" "$2" "$3" "$4" "$5" "${1%$5}"
        set -- "$1" "$2" "$3%%%02x" "$4" "$5" "$6"
        case "$6" in
            \ ) set -- "$5" "$2" "$3" "$4 32" "$5" "$6";;
            *) set -- "$5" "$2" "$3" "$4 '$6" "$5" "$6";;
        esac
    done
    set "$3" "$4" "$IFS"; IFS=' '
    printf "$1" $2
    IFS="$3"
}

next_line() {
    if [ -n "${1-}" ]; then awk "/$1/ {getline; print;}"; else head -n 1; fi
}

get_all_episodes() { #1:series
    curl -fs "$TV_URL/$(url_encode "$SERIES")/" \
        | jq -r '.[] | .name' \
        | grep -v '\.srt'
}

get_next_episode() { #1:series 2:episodename
    get_all_episodes "$1" | next_line "$(url_decode "$2")"
}

watch() { #1:series 2:episodename
    mkdir -p "$XDG_DATA_HOME/tv"
    echo "$2" >"$XDG_DATA_HOME/tv/$SERIES"
    ${PLAYER:-mpv} "$TV_URL/$(url_encode "$1")/$(url_encode "$2")"
}

serie() {
    recently_watched="$(mktemp)"
    ls -t "$XDG_DATA_HOME/tv" >"$recently_watched"
    SERIES="$(curl -fs "$TV_URL/" \
        | jq -r '.[] | .name' \
        | cat "$recently_watched" - \
        | awk '!_[$0]++' \
        | fzy)"
    rm "$recently_watched"
    case "${1:-$(printf "next\ncurrent\nep\n" | fzy)}" in
    next)
        watch "$SERIES" "$(get_next_episode "$SERIES" \
            "$(cat "$XDG_DATA_HOME/tv/$SERIES" 2>/dev/null || true)")"
        ;;
    current)
        watch "$SERIES" "$(cat "$XDG_DATA_HOME/tv/$SERIES" 2>/dev/null ||true)"
        ;;
    ep)
        watch "$SERIES" "$(get_all_episodes | fzy)";;
    esac
        
}
serie "$@"
