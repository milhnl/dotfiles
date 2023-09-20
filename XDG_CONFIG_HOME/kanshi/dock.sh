#!/usr/bin/env sh
daemon() ( exec "$@" >/dev/null 2>&1 & ); \

sudo modprobe i2c-dev
swaymsg output "'GIGA-BYTE TECHNOLOGY CO., LTD. M28U 22170B000449' `
    `scale $(swaymsg -t get_outputs | jq -r '.[]
        | select("\(.make) \(.model) \(.serial)"
            == "GIGA-BYTE TECHNOLOGY CO., LTD. M28U 22170B000449")
        | .modes | max_by(.width).width / 3840 * 2')"

sudo systemctl start avahi-daemon;
ps -Aocomm | grep -qxF nqptp || daemon sudo nqptp
sleep 1
ps -Aocomm | grep -qxF shairport-sync || daemon shairport-sync -o pa
swaystatus update
