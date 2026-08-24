#!/usr/bin/env sh
set -eu

die() { if [ "$#" -gt 0 ]; then printf "%s\n" "$*" >&2; fi && exit 1; }
exists() { command -v "$1" >/dev/null 2>&1; }
fnmatch() { case "$2" in $1) return 0 ;; *) return 1 ;; esac }
in_dir() (cd "$1" && shift && "$@")
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

apk_repo_path() {
	awk -v ALPINE_BRANCH="$ALPINE_BRANCH" '
		NR == FNR {
			if ($0 ~ /^[\/]media[\/][^\/]*[\/]apks/) next;
			p = match($0, /[\/][^\/]+[\/][^\/]+$/)
			prefs[n++] = substr($0, 1, p); next
		}
		{
			if (match($0, /^[\/]media[\/][^\/]*[\/]apks[\/]/)) {
				print ALPINE_BRANCH "/main/" substr($0, RSTART + RLENGTH)
				next
			}
			for (i = 0; i < n; i++) {
				if (index($0, prefs[i]) == 1) {
					print substr($0, length(prefs[i]) + 1)
					next
				}
			}
			print $0
		}' "${APKREPOS_PATH:-/etc/apk/repositories}" -
}

apk_repofetch() (
	host_alpine_branch="$(alpine_version_to_branch)"
	ARCH="$(apk --print-arch)"
	[ "$(id -u)" = 0 ] \
		&& ALPINE_LOCAL="${ALPINE_LOCAL:-/usr/local/share/alpine-repo}" \
		|| ALPINE_LOCAL="${ALPINE_LOCAL:-$XDG_CACHE_HOME/alpine-repo}"
	unset ROOT
	while getopts 'b:p:m:' OPT "$@"; do
		case "$OPT" in
		b) ALPINE_BRANCH="$OPTARG" ;;
		m) ARCH="$OPTARG" ;;
		p) ROOT="$OPTARG" ;;
		*) die "ERROR: Unknown option: %OPT" ;;
		esac
	done
	shift $((OPTIND - 1)) && OPTIND=1
	[ "$(id -u)" = 0 ] || die "Error: need to be root"
	export REPODEST="/usr/local/share/alpine-repo/$ALPINE_BRANCH"
	exists abuild-keygen || exists abuild-sign \
		|| apk add -q abuild apk-tools
	repositories="$(mktemp)"
	prepend /etc/apk/repositories "$ALPINE_LOCAL/$host_alpine_branch/main"
	prepend /etc/apk/repositories "$ALPINE_LOCAL/$host_alpine_branch/community"
	if ! abuild-sign -e >/dev/null 2>&1; then
		abuild-keygen -qani
	fi
	while IFS="$(printf \\n)" read -r repo; do
		case "$repo" in
		" #"* | "#"*) continue ;;
		/media/*)
			! [ -e "$repo/$ARCH" ] \
				|| [ "$host_alpine_branch" != "$ALPINE_BRANCH" ] \
				|| printf %s\\n "$repo"
			continue
			;;
		esac
		repo="$(echo "$repo" | sed "s/$host_alpine_branch/$ALPINE_BRANCH/")"
		if
			! fnmatch 'http*' "$repo" && [ ! -e "$repo/$ARCH/APKINDEX.tar.gz" ]
		then
			mkdir -p "$repo/$ARCH/"
			apk index --no-warnings -qo "$repo/$ARCH/APKINDEX.tar.gz"
			abuild-sign -q "$repo/$ARCH/APKINDEX.tar.gz"
		fi
		printf %s\\n "$repo"
	done </etc/apk/repositories >"$repositories"

	if [ "$ARCH" != "$(apk --print-arch)" ]; then
		cp "/usr/share/apk/keys/$ARCH"/* /etc/apk/keys
		apk update --arch "$ARCH" --repositories-file "$repositories" -q
	fi
	apk fetch --arch "$ARCH" --arch noarch \
		--repositories-file "$repositories" --recursive --url --simulate "$@" \
		| while read -r uri; do
			target="${ROOT-}$ALPINE_LOCAL/$(
				echo "$uri" | APKREPOS_PATH="$repositories" apk_repo_path
			)"
			name="$(basename "$uri" | sed -E 's/^(.*)-[0-9].*/\1/')"
			repo="$(dirname "$(dirname "$target")")"
			if [ ! "$uri" -ef "$target" ]; then
				mkdir -p "$repo/$ARCH" "$repo/noarch"
				apk fetch --arch "$ARCH" --arch noarch \
					--repositories-file "$repositories" \
					-o "$(dirname "$target")" \
					"$name"
			fi
			pkg="$(
				tar -xOf "$target" .PKGINFO | awk -vFS=' = ' '
						/^[^#]/ {
							m[$1] = substr($0, length($1) + 4)
						}
						END {
							printf("%s/%s-%s.apk",
								m["arch"], m["pkgname"], m["pkgver"])
						}'
			)"
			arch="${pkg%%/*}"
			pkg="${pkg#"$arch"/}"
			if ! [ "$repo/$ARCH/$pkg" -ef "$repo/$arch/$pkg" ]; then
				if [ "$arch" = noarch ]; then
					! [ -e "$repo/$ARCH/$pkg" ] \
						|| mv "$repo/$ARCH/$pkg" "$repo/noarch/$pkg"
					ln -fs "../noarch/$pkg" "$repo/$ARCH/$pkg"
				fi
			fi
		done
	for repo in "${ROOT-}$ALPINE_LOCAL"/*/*/*; do
		find "$repo" -iname '*.apk' -exec \
			apk index -qo "$repo/APKINDEX.tar.gz" \{\} \+
		[ ! -e "$repo/APKINDEX.tar.gz" ] \
			|| abuild-sign -q "$repo"/APKINDEX.tar.gz
	done
	if [ -n "${ROOT-}" ] && [ "$ROOT" != / ]; then
		mkdir -p "${ROOT-}/etc/apk/keys/"
		cp -r /etc/apk/keys/. "$ROOT/etc/apk/keys/"
	fi
)

apk_repofetch "$@"
