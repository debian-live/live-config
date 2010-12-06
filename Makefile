# Makefile

SHELL := sh -e

LANGUAGES = de fr pt_BR

SCRIPTS = bin/* scripts/*.sh scripts/*/*

all: build

test:
	@echo -n "Checking for syntax errors"

	@for SCRIPT in $(SCRIPTS); \
	do \
		sh -n $${SCRIPT}; \
		echo -n "."; \
	done

	@echo " done."

	@if [ -x "$$(which checkbashisms 2>/dev/null)" ]; \
	then \
		echo -n "Checking for bashisms"; \
		for SCRIPT in $(SCRIPTS); \
		do \
			checkbashisms -f -x $${SCRIPT}; \
			echo -n "."; \
		done; \
		echo " done."; \
	else \
		echo "W: checkbashisms - command not found"; \
		echo "I: checkbashisms can be optained from: "; \
		echo "I:   http://git.debian.org/?p=devscripts/devscripts.git"; \
		echo "I: On Debian systems, checkbashisms can be installed with:"; \
		echo "I:   apt-get install devscripts"; \
	fi

build:
	@echo "Nothing to build."

install:
	# Installing scripts
	mkdir -p $(DESTDIR)/lib/live
	cp -r scripts/config.sh scripts/config $(DESTDIR)/lib/live
	mkdir -p $(DESTDIR)/var/lib/live/config

	# Installing docs
	mkdir -p $(DESTDIR)/usr/share/doc/live-config
	cp -r COPYING examples $(DESTDIR)/usr/share/doc/live-config

	# Installing manpages
	for MANPAGE in manpages/en/*; \
	do \
		SECTION="$$(basename $${MANPAGE} | awk -F. '{ print $$2 }')"; \
		install -D -m 0644 $${MANPAGE} $(DESTDIR)/usr/share/man/man$${SECTION}/$$(basename $${MANPAGE}); \
	done

	for LANGUAGE in $(LANGUAGES); \
	do \
		for MANPAGE in manpages/$${LANGUAGE}/*; \
		do \
			SECTION="$$(basename $${MANPAGE} | awk -F. '{ print $$3 }')"; \
			install -D -m 0644 $${MANPAGE} $(DESTDIR)/usr/share/man/$${LANGUAGE}/man$${SECTION}/$$(basename $${MANPAGE} .$${LANGUAGE}.$${SECTION}).$${SECTION}; \
		done; \
	done

uninstall:
	# Uninstalling scripts
	rm -rf $(DESTDIR)/lib/live/config.sh $(DESTDIR)/lib/live/config
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/lib/live || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/lib || true

	rmdir --ignore-fail-on-non-empty $(DESTDIR)/var/lib/live/config || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/var/lib/live || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/var/lib || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/var || true

	# Uninstalling docs
	rm -rf $(DESTDIR)/usr/share/doc/live-config
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr/share/doc
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr/share
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr

	# Uninstalling manpages
	for MANPAGE in manpages/en/*; \
	do \
		SECTION="$$(basename $${MANPAGE} | awk -F. '{ print $$2 }')"; \
		rm -f $(DESTDIR)/usr/share/man/man$${SECTION}/$$(basename $${MANPAGE} .en.$${SECTION}).$${SECTION}; \
	done

	for LANGUAGE in $(LANGUAGES); \
	do \
		for MANPAGE in manpages/$${LANGUAGE}/*; \
		do \
			SECTION="$$(basename $${MANPAGE} | awk -F. '{ print $$3 }')"; \
			rm -f $(DESTDIR)/usr/share/man/$${LANGUAGE}/man$${SECTION}/$$(basename $${MANPAGE} .$${LANGUAGE}.$${SECTION}).$${SECTION}; \
		done; \
	done

	for SECTION in $(ls manpages/en/* | awk -F. '{ print $2 }'); \
	do \
		rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr/share/man/man$${SECTION} || true; \
		rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr/share/man/*/man$${SECTION} || true; \
	done

	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr/share/man || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr/share || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/usr || true

	rmdir --ignore-fail-on-non-empty $(DESTDIR) || true

clean:
	@echo "Nothing to clean."

distclean: clean
	@echo "Nothing to distclean."

reinstall: uninstall install
