# shellcheck shell=sh disable=SC2123

command_without_override() (
	for dir in \
		"$PREFIX/lib/sh/override" "$PREFIX/lib/sh/override/$(uname -s)"; do
		case "$PATH" in
		"$dir") PATH="" ;;
		"$dir":*) PATH="${PATH#*:}" ;;
		*:"$dir") PATH="${PATH%:"$dir"}" ;;
		*:"$dir":*) PATH="${PATH%%:"$dir":*}:${PATH#*:"$dir":}" ;;
		esac
	done
	command -v "$1"
)
