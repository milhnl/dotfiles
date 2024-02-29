#!/usr/bin/env sh
set -eu

die() { printf '%s\n' "$*" >&2; exit 1; }
exists() { command -v "$1" >/dev/null 2>&1; }
fnmatch() { case "$2" in $1) return 0 ;; *) return 1 ;; esac ; }

tasmota_mqtt_transport() {
    case "$2" in
    *";"*) set -- "$1" "Backlog" "$2" ;;
    *)
        set -- "$1" "${2%% *}" "${2#${2%% *}}"
        set -- "$1" "$2" "${3# }"
        ;;
    esac
    case "$MQTT_HOST" in
    *:*)
        MQTT_PORT="${MQTT_HOST##*:}"
        MQTT_HOST="${MQTT_HOST%:*}"
        ;;
    *) ;;
    esac
    mosquitto_pub -h "$MQTT_HOST" ${MQTT_PORT+-p $MQTT_PORT} \
        -t "cmnd/$1/$2" -m "$3"
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
        if exists avahi-browse; then
            MQTT_HOST="$(avahi-browse -krpt _mqtt._tcp \
                | awk -v FS=\; '/^=/ { printf("%s:%d", $7, $9); exit; }')"
        elif exists dns-sd; then
            MQTT_HOST="$(dns-sd -t 1 -Z _mqtt._tcp | awk '{
                    if ($2 == "SRV") {
                        printf("%s:%d", substr($6, 1, length($6) - 1), $5)
                        exit
                    }
                }'
            )"
        else
            die "ERROR: can't autodetect MQTT broker"
        fi
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
