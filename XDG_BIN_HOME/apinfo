#!/usr/bin/env sh
set -eu

lowercase_vars() {
    sed -e 'h;s/:.*//' \
        -e 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/' \
        -e 'x;s/[^:]*://;H;x;s/\n/:/'
}

case `uname -s` in
Darwin)
    PATH="$PATH:/System/Library/PrivateFrameworks/Apple80211.framework"
    PATH="$PATH/Versions/A/Resources"
    airport -I;;
Linux)
    iw dev wlan0 link;;
esac \
    | sed '
        s/:\s*/:/g
        s/^ *//;s/^\s*//
        s/.*\([0-9a-f:]\{17\}\).*/BSSID:\1/
        s/\(-[0-9]*\) dBm/\1/
    ' \
    | lowercase_vars \
    | awk -v OFS='\t' '
        {
            o[substr($0, 0, index($0, ":") - 1)] = \
                substr($0, index($0, ":") + 1);
        }
        END {
            if (o["signal"] == "") {
                o["snr"] = o["agrctlnoise"] - o["agrctlrssi"];
            } else {
                #Maybe this is actually the RSSI?
                o["snr"] = o["signal"];
            }
            if (o["channel"] == "") {
                if (o["freq"] > 2401 && o["freq"] < 2495) {
                    o["channel"] = (o["freq"] - 2407) / 5;
                } else {
                    o["channel"] = "5GHz"
                }
            }
            print o["bssid"], o["snr"], o["channel"], o["ssid"];
        }
    '
