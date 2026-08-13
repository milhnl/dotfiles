.POSIX:
.SILENT:
.PHONY: install uninstall

install: sysusers.sh
	mkdir -p "${DESTDIR}${PREFIX}/bin"
	cp sysusers.sh "${DESTDIR}${PREFIX}/bin/systemd-sysusers"
	chmod a+rx "${DESTDIR}${PREFIX}/bin/systemd-sysusers"
	ln -s "${DESTDIR}${PREFIX}/bin/systemd-sysusers" \
		"${DESTDIR}${PREFIX}/bin/systemd-tmpfiles"
	chmod a+rx "${DESTDIR}${PREFIX}/bin/systemd-tmpfiles"

uninstall:
	rm -f "${DESTDIR}${PREFIX}/bin/systemd-sysusers"
	rm -f "${DESTDIR}${PREFIX}/bin/systemd-tmpfiles"
