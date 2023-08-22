#!/usr/bin/env sh
set -eu

playerctl -p ShairportSync status | grep -qxF Playing \
    || { pkill shairport-sync; sudo pkill nqptp; }
swaystatus update
