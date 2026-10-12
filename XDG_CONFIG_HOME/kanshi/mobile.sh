#!/usr/bin/env sh
set -eu

playerctl -p ShairportSync status | grep -qxF Playing \
    || systemctl --user stop shairport-sync
swaystatus update
