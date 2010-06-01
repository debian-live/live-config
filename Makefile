# Makefile

SHELL := sh -e

LANGUAGES = de

SCRIPTS = examples/scripts/* scripts/config.sh scripts/config/*

all: test build

test:
	@echo -n "Checking for syntax errors"

	@for SCRIPT in $(SCRIPTS); \
	do \
		sh -n $${SCRIPT}; \
		echo -n "."; \
	done

	@echo " done."

	@echo -n "Checking for bashisms"

	@if [ -x /usr/bin/checkbashisms ]; \
	then \
		for SCRIPT in $(SCRIPTS); \
		do \
			checkbashisms -f -x $${SCRIPT}; \
			echo -n "."; \
		done; \
	else \
		echo "WARNING: skipping bashism test - you need to install devscripts."; \
	fi

	@echo " done."

build:
	@echo "Nothing to build."

install:
	# Installing scripts
	mkdir -p $(DESTDIR)/lib/live
	cp -r scripts/config.sh scripts/config $(DESTDIR)/lib/live
	mkdir -p $(DESTDIR)/var/lib/live/config

	# Installing docs
	mkdir -p $(DESTDIR)/usr/share/doc/live-config
	cp -r COPYING docs/* examples $(DESTDIR)/usr/share/doc/live-config

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
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/var/lib/live/config || true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/var/lib/live || true

	# Uninstalling docs
	rm -rf $(DESTDIR)/usr/share/doc/live-config

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

clean:

distclean:

reinstall: uninstall install
