#!/usr/bin/env sh
#ump - universal media player
set -eu

# COMMON ----------------------------------------------------------------------
daemon() ( exec "$@" >/dev/null 2>&1 & )

# PROVIDER: YOUTUBE -----------------------------------------------------------
mpv_ensure_running() {
    ps -Aocomm | grep -q mpv || daemon mpv --idle
}

mpv_command() {
    mpv_ensure_running
    {
        printf '{ "command": ['
        for x; do printf '"%s",' "$x"; done
        echo ']}'
    } | nc -U "$XDG_CONFIG_HOME/mpv/socket"
}

ump_youtube() {
    case "$1" in
    now) shift; mpv_command loadfile "ytdl://ytsearch:$*";;
    add) shift; mpv_command loadfile "ytdl://ytsearch:$*" append-play;;
    toggle) mpv_command cycle pause;;
    prev) shift; mpv_command playlist_prev;;
    next) shift; mpv_command playlist_next;;
    esac
}

ump() {
    ump_youtube "$@"
}

ump "$@"
