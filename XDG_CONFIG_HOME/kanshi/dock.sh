#!/usr/bin/env sh

sudo modprobe i2c-dev
swaymsg output "'GIGA-BYTE TECHNOLOGY CO., LTD. M28U 22170B000449' $(
)scale $(swaymsg -t get_outputs | jq -r '.[]
        | select("\(.make) \(.model) \(.serial)"
            == "GIGA-BYTE TECHNOLOGY CO., LTD. M28U 22170B000449")
        | .modes | max_by(.width).width / 3840 * 2')"
service-shairport-sync start
