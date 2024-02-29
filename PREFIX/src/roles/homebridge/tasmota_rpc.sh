#!/usr/bin/env sh
set -eu

fnmatch() { case "$2" in $1) return 0 ;; *) return 1 ;; esac ; }

tasmota_mqtt_transport() {
    case "$2" in
    *";"*) set -- "$1" "Backlog" "$2" ;;
    *)
        set -- "$1" "${2%% *}" "${2#${2%% *}}"
        set -- "$1" "$2" "${3# }"
        ;;
    esac
    mosquitto_pub -h "${MQTT_HOST%:*}" -t "cmnd/$1/$2" -m "$3"
}

tasmota_http_transport() {
    curl -s "http://$1/cm?cmnd=$( (fnmatch '*;*' "$2" \
        && printf 'Backlog %s' "$2" || printf '%s' "$2") | jq -sRr @uri)"
}

tasmota_rpc() {
    while getopts "h:t:c:" OPT "$@"; do
        case "$OPT" in
        h) MQTT_HOST="$OPTARG";;
        t) TRANSPORT="$OPTARG";;
        c) backlog="${backlog-}$(printf "${backlog+; }%s" "$OPTARG")" ;;
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
