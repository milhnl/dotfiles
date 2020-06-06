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

reorder() {
    awk '
        {
            if (!pivot)
                buf = buf $0 ORS;
            else
                print $0;
            if ($0 == "'"$1"'") pivot = 1;
        }
        END { printf("%s", buf); }'
}

get_all_episodes() { #1:series
    curl -fs "$TV_URL/$(url_encode "$1")/" \
        | jq -r '.[] | .name' \
        | grep -v '\.srt'
}

watch() { #1:series 2:episodename
    mkdir -p "$XDG_DATA_HOME/tv"
    echo "$2" >"$XDG_DATA_HOME/tv/$1"
    ${PLAYER:-mpv} "$TV_URL/$(url_encode "$1")/$(url_encode "$2")"
}

serie() {
    recently_watched="$(mktemp)"
    ls -t "$XDG_DATA_HOME/tv" >"$recently_watched"
    set -- "$(curl -fs "$TV_URL/" \
        | jq -r '.[] | .name' \
        | cat "$recently_watched" - \
        | awk '!_[$0]++' \
        | fzy)"
    rm "$recently_watched"
    set -- "$1" "$(get_all_episodes "$1" \
        | reorder "$(cat "$XDG_DATA_HOME/tv/$1" 2>/dev/null || true)" \
        | fzy)"
    watch "$1" "$2"
}
serie "$@"
