#!/usr/bin/env sh
#ump - universal media player
set -eu

# COMMON ----------------------------------------------------------------------
daemon() ( exec "$@" >/dev/null 2>&1 & )
die() { printf '%s\n' "$*" >&2; exit 1; }

# PROVIDER: YOUTUBE -----------------------------------------------------------
mpv_ensure_running() {
    ps -Aocomm | grep -q mpv && [ -S "$XDG_CONFIG_HOME/mpv/socket" ] \
        || daemon mpv --idle --input-ipc-server"=~~/socket" \
        || die "Can't start idle mpv"
    until mpv_command get_version >/dev/null; do sleep 1; done
}

mpv_command() {
    {
        printf '{ "command": ['
        for x; do printf '"%s",' "$x"; done
        echo ']}'
    } | nc -U "$XDG_CONFIG_HOME/mpv/socket"
}

ump_youtube() {
    mpv_ensure_running
    case "$1" in
    now) shift; mpv_command loadfile "ytdl://ytsearch:$*";;
    add) shift; mpv_command loadfile "ytdl://ytsearch:$*" append-play;;
    toggle) mpv_command cycle pause;;
    prev) shift; mpv_command playlist_prev;;
    next) shift; mpv_command playlist_next;;
    *) die 'Error: unsupported operation';;
    esac
}

ump() {
    ump_youtube "$@"
}

ump "$@"
