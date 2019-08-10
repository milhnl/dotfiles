.POSIX:
.SILENT:
.PHONY: install uninstall link update
common = set -a; \
	PREFIX="$${PREFIX:-$$HOME/.local}"; \
	XDG_BIN_HOME="$${XDG_BIN_HOME:-$$HOME/.local/bin}"; \
	XDG_CACHE_HOME="$${XDG_CACHE_HOME:-$$HOME/.cache}"; \
	XDG_CONFIG_HOME="$${XDG_CONFIG_HOME:-$$HOME/.config}"; \
	XDG_DATA_HOME="$${XDG_DATA_HOME:-$$HOME/.local/share}"; \
	PWD="$${PWD:-$(pwd)}"; \
	for_all() { \
		find * -not -type d -exec sh -c 'for i; do \
			f="$$(printenv "$${i%%/*}")/$${i\#*/}" || continue; \
			'"$$*"'; \
		done' -- {} +; \
	}

install:; ${common}; for_all 'cp "$$i" "$$f"'
uninstall:; ${common}; for_all 'rm -rf "$$f"'
link:; ${common}; for_all 'mkdir -p "$${f%/*}"; ln -fs "$$PWD/$$i" "$$f"'
update:; ${common}; for_all 'cp "$$f" "$$i"'
