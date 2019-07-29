.POSIX:
.SILENT:
.PHONY: all install pull

all: install

install:
	for envkey in * ; do \
		[ -e "$$envkey" ] || continue; \
		fsfile="`printenv $$(basename "$$envkey"|sed 's/[^A-Za-z0-9\_]//g')`"; \
		[ -d "$$envkey" ] && envkey="$$envkey/."; \
		[ -e "$$fsfile" ] || continue; \
		cp -a "$$envkey" "$$fsfile" || return 1; \
	done;

pull:
	# TODO: create script that'll pull all files already in the repo from the
	# filesystem itself. Good enough, and no dotfile manager except for this
	# Makefile you're reading.
	false
