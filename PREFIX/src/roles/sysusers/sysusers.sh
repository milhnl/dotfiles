#!/usr/bin/env sh
# shellcheck disable=SC2012
#sysusers - portably apply systemd-sysusers syntax
set -eu

escape() { printf %s "$1" | sed "s/'/'\\\\''/g"; }
exists() { command -v "$1" >/dev/null 2>&1; }
fnmatch() { case "$2" in $1) return 0 ;; *) return 1 ;; esac }

sd_tools_parse_config() {
	awk '
		function escape(s,  r) {
			if (s ~ /^[A-Za-z0-9\/_.,-]+$/) {
				return s
			} else {
				r = s
				gsub(/\\/, "\\\\", r)
				gsub(/\047/, "\\047", r)
				gsub(/\011/, "\\011", r)
				gsub(/ /, "\\040", r)
				return "$\047" r "\047"
			}
		}
		function join(fields,  out) {
			for (i = 1; i in fields; i++)
				out = out (out ? " " : "") escape(fields[i])
			return out
		}
		/^[ \t]*(#|$)/ { next }
		{
			delete fields
			n = 1
			len = length($0)
			i = 1
			while (i <= len) {
				while (i <= len && substr($0, i, 1) ~ /[ \t]/)
					i++
				if (i > len)
					break
				quote = ""
				while (i <= len) {
					c = substr($0, i++, 1)
					if (c == "\\") {
						c = substr($0, i++, 1)
						if (c == "") {
							printf "%s:%d: trailing backslash\n",
								   FILENAME, FNR >"/dev/stderr"
							exit 1
						}
						fields[n] = fields[n] c
					} else if (quote != "") {
						if (c == quote)
							quote = ""
						else
							fields[n] = fields[n] c
					} else if (c == "\"" || c == "\047") {
						quote = c
						fields[n] = fields[n]
					} else if (c ~ /[ \t]/) {
						break
					} else {
						fields[n] = fields[n] c
					}
				}
				n += 1
			}
			if (quote != "") {
				printf "%s:%d: unmatched quote (%s) at pos (%i)\n",
					FILENAME, FNR, quote, i >"/dev/stderr"
				next
			}
			print join(fields)
		}
	' "$@"
}

translate_sysusers() {
	sd_tools_parse_config "$@" | awk -F\  '
		function unescape(s,  r) {
			if (s ~ /^\$/) {
				r = substr(s, 3, length(s) - 3)
				gsub(/\\047/, "\047", r)
				gsub(/\\040/, "\040", r)
				gsub(/\\011/, "\011", r)
				gsub(/\\\\/, "\\", r)
				return r
			} else {
				return s
			}
		}
		function join(fields,  out) {
			for (i = 1; i in fields; i++)
				out = out (out ? " " : "") fields[i]
			return out
		}
		function append(fields) {
			#print join(fields)
			if (unescape(fields[1]) ~ /^u!?/) {
				users = users \
					sprintf("sysusers_apply_line %s\n", join(fields))
			} else if (fields[1] == "g") {
				groups = groups \
					sprintf("sysusers_apply_line %s\n", join(fields))
			} else if (fields[1] == "m") {
				implicit_group[1] = "g"
				implicit_group[2] = fields[3]
				implicit_group[3] = "-"
				append(implicit_group)
				implicit_user[1] = "u"
				implicit_user[2] = fields[2]
				implicit_user[3] = "-"
				append(implicit_user)
				supplementaries = supplementaries \
					sprintf("sysusers_apply_line %s\n", join(fields))
			}
		}
		{
			for (k in fields)
				delete fields[k]
			for (i = 1; i <= NF; i++)
				fields[i] = $i
			append(fields)
		}
		END {
			printf("%s", groups)
			printf("%s", users)
			printf("%s", supplementaries)
		}
	'
}

getent_exists() { #1: db 2: user_or_group_name_or_id
	if exists getent && [ $# -eq 2 ]; then
		getent "$@"
	else
		<"/etc/$1" awk -F: -v q="${2-}" -v hasquery="${2+nonempty}" '
			BEGIN { n = (q ~ /^[0-9]+$/) ? 3 : 1 }
			!hasquery || $n == q { print; found = 1 }
			END { exit !found }
		'
	fi
}

sysusers_apply_line() { #1: type 2: name 3: id 4: gecos 5: home 6: shell
	[ $# -ge 3 ] || { printf "Usage: %s TYPE NAME ID\n" "$0" >&2 && return 1; }
	case "$1" in
	"u" | "u!")
		set -- "$1" "$2" "$3" "${4:--}" "${5:--}" "${6:--}"
		case "$3" in
		/*)
			set -- "$1" "$2" "$(
				LC_ALL=C ls -Ldn "$3" | awk '{ print $3 " " $4 }'
			)" "$4" "$5" "$6" "" "$3"
			set -- "$1" "$2" "${3% *}" "$4" "$5" "$6" "${3#* }" "$8"
			;;
		*:*)
			set -- "$1" "$2" "${3%:*}" "$4" "$5" "$6" "${3#*:}"
			;;
		esac
		[ -n "$3" ] || set -- "$1" "$2" "-" "$4" "$5" "$6"
		if getent_exists passwd "$2" >/dev/null 2>&1; then
			if [ -z "${7-}" ] || [ -n "${8-}" ]; then
				sysusers_apply_line g "$2" "${7-$3}"
			elif ! getent_exists group "$7" >/dev/null; then
				printf "Group %s not found\n" "$7" >&2
				return 1
			fi
			return $?
		fi
		#Remove request for specific UID if it is in use
		[ "$3" = - ] || ! getent_exists passwd "$3" >/dev/null \
			|| set -- "$1" "$2" "-" "$4" "$5" "$6" "${7-}" "${8-}"
		#Default GECOS field should be empty instead of Linux User or whatever
		[ "${4:--}" != - ] \
			|| set -- "$1" "$2" "$3" "" "$5" "$6" "${7-}" "${8-}"
		#Default home dir is /, would be in /home otherwise
		[ "${5:--}" != - ] \
			|| set -- "$1" "$2" "$3" "$4" "/" "$6" "${7-}" "${8-}"
		#Default shell is sh for root (huh? who...) or nologin equivalent
		[ "${6:--}" != - ] \
			|| set -- "$1" "$2" "$3" "$4" "$5" "$(
				[ "$3" != 0 ] || { printf /bin/sh && return; }
				for x in /usr/sbin/nologin /sbin/nologin /bin/false; do
					! [ -x "$x" ] || break
				done
				printf %s "$x"
			)" "${7-}" "${8-}"
		if [ -n "${8-}" ]; then #gid is from a file, so numeric
			sysusers_apply_line g "$2" "$7" || return 1
			set -- "$1" "$2" "$3" "$4" "$5" "$6" "$2"
		fi
		if exists useradd && useradd 2>&1 | grep -q badname; then #shadow-utils
			[ -n "${7-}" ] || ! getent_exists group "$2" >/dev/null \
				|| set -- "$1" "$2" "$3" "$4" "$5" "$6" "$2"
			eval "$(
				printf 'useradd --system --no-create-home'
				[ "$1" != "u!" ] || printf " --expiredate '1'"
				[ "${3:--}" = - ] || printf " --uid '%s'" "$(escape "$3")"
				printf " --comment '%s'" "$(escape "$4")"
				printf " --home-dir '%s'" "$(escape "$5")"
				printf " --shell '%s'" "$(escape "$6")"
				[ "${7:--}" = - ] \
					&& printf " --user-group" \
					|| printf " --no-user-group --gid '%s'" "$(escape "$7")"
				printf " '%s'" "$(escape "$2")"
			)"
		elif exists adduser && adduser 2>&1 | grep -q BusyBox; then #BusyBox
			if [ -z "${7-}" ]; then
				sysusers_apply_line g "$2" - || return 1
				set -- "$1" "$2" "$3" "$4" "$5" "$6" "$2"
			fi
			eval "$(
				printf 'adduser -S -H -D'
				[ "${3:--}" = - ] || printf " -u '%s'" "$(escape "$3")"
				printf " -g '%s'" "$(escape "$4")"
				printf " -h '%s'" "$(escape "$5")"
				printf " -s '%s'" "$(escape "$6")"
				[ "${7:--}" = - ] || printf " -G '%s'" "$(escape "$7")"
				printf " '%s'" "$(escape "$2")"
			)"
			[ "$1" != "u!" ] \
				|| printf "Warning: can't actually lock user\n" >&2
		else
			printf 'Error: No way to add users found\n' >&2
			return 1
		fi
		;;
	"g")
		! getent_exists group "$2" >/dev/null \
			|| return 0
		case "$3" in
		/*) set -- "$1" "$2" "$(LC_ALL=C ls -Ldn "$3" | awk '{ print $4 }')" ;;
		esac
		[ -n "$3" ] || set -- "$1" "$2" "-"
		#Remove request for specific GID if it is in use
		! getent_exists group "$3" >/dev/null \
			|| set -- "$1" "$2" "-"
		if exists groupadd; then
			eval "$(
				printf 'groupadd --system'
				[ "${3:--}" = - ] || printf " --gid '%s'" "$(escape "$3")"
				printf " '%s'" "$(escape "$2")"
			)"
		elif exists addgroup && addgroup 2>&1 | grep -q BusyBox; then #BusyBox
			eval "$(
				printf 'addgroup -S'
				[ "${3:--}" = - ] || printf " -g '%s'" "$(escape "$3")"
				printf " '%s'" "$(escape "$2")"
			)"
		else
			printf 'No way to add groups found' >&2
			return 1
		fi
		;;
	"m")
		if exists usermod; then
			eval "$(
				printf "usermod -aG '%s' '%s'" "$(escape "$3")" \
					"$(escape "$2")"
			)"
		elif exists addgroup && addgroup 2>&1 | grep -q BusyBox; then #BusyBox
			eval "$(
				printf "addgroup '%s' '%s'" "$(escape "$2")" "$(escape "$3")"
			)"
		else
			printf 'No way to add users to groups found' >&2
			return 1
		fi
		;;
	esac
}

handle_sysusers() {
	PATH="$PATH:/usr/sbin"
	eval "$(translate_sysusers "$@")"
}

translate_tmpfiles() {
	sd_tools_parse_config "$@" | awk -F\  '
		{
			printf("tmpfiles_apply_line ")
			print
		}
	'
}

tmpfiles_chownmod() { #1: file 2: mode 3: user 4: group 5: recursive
	chmod "$2" "$1"
	set -- "$1" "$2" "$3" "$4" "${5-}" "$(
		LC_ALL=C ls -Ldl "$1" | awk '{ print $3 " " $4 }'
	)"
	[ "${6% *}" = "$3" ] || chown "$3" "$1"
	[ "${6#* }" = "$4" ] || chgrp "$4" "$1"
}

tmpfiles_apply_line() {
	[ $# -ge 2 ] || { printf "Usage: %s TYPE PATH ..\n" "$0" >&2 && return 1; }
	set -- "$1" "$2" "${3:--}" "${4:--}" "${5:--}" "${6:--}" "${7:-}"
	[ "${4-}" != - ] || set -- "$1" "$2" "$3" "$(id -un)" "$5" "$6" "$7"
	[ "${5-}" != - ] || set -- "$1" "$2" "$3" "$4" "$(id -gn)" "$6" "$7"
	case "$1" in
	f* | w*)
		! fnmatch "w*" "$1" || [ -e "$2" ] || return 0
		if fnmatch "w*" "$1" || fnmatch "*+*" "$1" || ! [ -e "$2" ]; then
			echo "$7" | {
				case "$1" in
				*~*) base64 -d ;;
				*) cat ;;
				esac
			} | (
				mkdir -p "$(dirname "$2")"
				umask og-rwx
				case "$1" in
				w+) tee -a "$2" ;;
				*) tee "$2" ;;
				esac
			) >/dev/null
		fi
		tmpfiles_chownmod "$2" "$3" "$4" "$5"
		;;
	d* | D*)
		mkdir -p "$2"
		tmpfiles_chownmod "$2" "$3" "$4" "$5"
		;;
	C*)
		# shellcheck disable=SC2015
		[ -e "$2" ] && ! fnmatch "*+*" "$1" || cp -r "$7" "$2"
		tmpfiles_chownmod "$2" "$3" "$4" "$5" -r
		;;
	r)
		rm "$2"
		;;
	R)
		rm -r "$2"
		;;
	esac
}

handle_tmpfiles() {
	# shellcheck disable=SC2015
	[ "$1" = --create ] && shift \
		|| { printf "Only --create is supported\n" && exit 1; }
	eval "$(translate_tmpfiles "$@")"
}

sd_tools_multiplex() {
	case "$0" in
	*sysusers) handle_sysusers "$@" ;;
	*tmpfiles) handle_tmpfiles "$@" ;;
	*.sh) "$@" ;;
	esac
}

sd_tools_multiplex "$@"
