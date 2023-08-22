#!/usr/bin/env sh
daemon() ( exec "$@" >/dev/null 2>&1 & ); \

sudo systemctl start avahi-daemon;
ps -Aocomm | grep -qxF nqptp || daemon sudo nqptp
sleep 1
ps -Aocomm | grep -qxF shairport-sync || daemon shairport-sync -o pa
swaystatus update
