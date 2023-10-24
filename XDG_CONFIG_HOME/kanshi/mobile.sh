#!/usr/bin/env sh
set -eu

playerctl -p ShairportSync status | grep -qxF Playing \
    || service-shairport-sync stop
swaystatus update
