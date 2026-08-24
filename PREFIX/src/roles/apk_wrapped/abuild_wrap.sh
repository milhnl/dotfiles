#!/usr/bin/env sh
set -eu

sponge() { set -- "$1" "$(mktemp)" && cat >"$2" && sudo mv "$2" "$1"; }

prepend() {
	if ! <"$1" grep -qxF "$2"; then
		{ printf "%s\n" "$2" && cat "$1"; } | sponge "$1"
	fi
}

alpine_version_to_branch() { #1?: version
	[ $# -eq 1 ] || set -- "$(cat /etc/alpine-release)"
	case "$1" in
	*.*.*) set -- "${1%.*}" && echo "v${1#v}" ;;
	*) echo edge ;;
	esac
}

abuild_wrap() (
	ALPINE_BRANCH="$(alpine_version_to_branch)"
	export REPODEST="/usr/local/share/alpine-repo/$ALPINE_BRANCH"
	sudo apk add -q alpine-sdk
	sudo mkdir -p "$REPODEST"
	sudo chown -R root:abuild "$REPODEST"
	sudo chmod -R g+w "$REPODEST"
	prepend /etc/apk/repositories "$REPODEST/$(
		basename "$(dirname "$(dirname "${APKBUILD:-$PWD/APKBUILD}")")"
	)"
	USER="${USER-$(whoami)}"
	if [ "$(id -u)" -eq 0 ]; then
		if </etc/passwd grep -q '^mil:'; then
			ABUILDUSER=mil
		else
			ABUILDUSER=abuild
			</etc/passwd grep -q '^abuild:' \
				|| sudo adduser -s /bin/false -G abuild -D abuild
		fi
		WD="/usr/local/src/abuild-repo/$(
			basename "$(dirname "$PWD")"
		)/$(basename "$PWD")"
		mkdir -p "$WD"
		cp -r . "$WD"
		sudo chgrp -R abuild "$WD"
		sudo chmod -R g+rwX "$WD"
		cd "$WD" || return 1
	else
		ABUILDUSER="$USER"
	fi
	sudo addgroup "$ABUILDUSER" abuild
	set -- sh -c '
			if ! abuild-sign -e >/dev/null 2>&1; then
				abuild-keygen -qani
			fi
			abuild "$@"
	' -- "$@"
	# shellcheck disable=SC2015
	[ "$USER" = "$ABUILDUSER" ] && id -Gn | grep -qE '(^| )abuild( |$)' \
		|| set -- sudo -u "$ABUILDUSER" env REPODEST="$REPODEST" "$@"
	"$@"
)

abuild_wrap "$@"
