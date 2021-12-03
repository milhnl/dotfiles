#!/usr/bin/env sh
set -eu

tasmota_mqtt_transport() {
    mosquitto_pub -h "$MQTT_HOST" -t "cmnd/$1/Backlog" -m "$2"
}

tasmota_http_transport() {
    curl "http://$1/cm?cmnd=$(echo "Backlog $2" | jq -sRr @uri)"
}

tasmota_rpc() {
    while getopts "h:t:c:" OPT "$@"; do
        case "$OPT" in
        h) MQTT_HOST="$OPTARG";;
        t) TRANSPORT="$OPTARG";;
        c) backlog="${backlog-}$(echo "$OPTARG" | sed 's/$/; /')";;
        esac
    done
    if [ "${TRANSPORT-mqtt}" = mqtt ] && [ -z "${MQTT_HOST-}" ]; then
        MQTT_HOST="$(avahi-browse -krpt _mqtt._tcp \
            | awk -v FS=\; '/^=/ { printf("%s", $7); exit; }')"
    fi
    shift "$(( $OPTIND - 1 ))"
    for host; do
        case "${TRANSPORT-mqtt}" in
        mqtt) tasmota_mqtt_transport "$host" "$backlog";;
        http) tasmota_http_transport "$host" "$backlog";;
        esac
    done
}

tasmota_rpc "$@"
