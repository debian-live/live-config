#!/bin/sh

## live-config(7) - System Configuration Scripts
## Copyright (C) 2006-2012 Daniel Baumann <daniel@debian.org>
##
## live-config comes with ABSOLUTELY NO WARRANTY; for details see COPYING.
## This is free software, and you are welcome to redistribute it
## under certain conditions; see COPYING for details.


set -e

DATE="$(LC_ALL=C date +%Y\\\\-%m\\\\-%d)"
PROGRAM="LIVE\\\-CONFIG"
VERSION="$(cat ../VERSION)"

echo "Updating version headers..."

for MANPAGE in en/*
do
	SECTION="$(basename ${MANPAGE} | awk -F. '{ print $2 }')"

	sed -i -e "s|^.TH.*$|.TH ${PROGRAM} ${SECTION} ${DATE} ${VERSION} \"Debian Live Project\"|" ${MANPAGE}
done
