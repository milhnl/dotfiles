.POSIX:
.SILENT:
.PHONY: install uninstall

install: sysusers.sh
	mkdir -p "${DESTDIR}${PREFIX}/bin"
	cp sysusers.sh "${DESTDIR}${PREFIX}/bin/sysusers"
	chmod a+rx "${DESTDIR}${PREFIX}/bin/sysusers"

uninstall:
	rm -f "${DESTDIR}${PREFIX}/bin/sysusers"
