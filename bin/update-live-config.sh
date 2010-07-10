#!/bin/sh

set -e

DIRECTORY="${1:-/lib/live/config}"

if [ ! -e "${DIRECTORY}" ]
then
	echo "E: ${DIRECTORY} - not found."
	exit 1
fi

DISTRIBUTION="$(lsb_release -is | tr [A-Z] [a-z])"
RELEASE="$(lsb_release -cs | tr [A-Z] [a-z])"

echo "Removing unused scripts..."

case "${DISTRIBUTION}" in
	debian)
		# Removing ubuntu scripts
		rm -f "${DIRECTORY}"/*-apport

		case "${RELEASE}" in
		lenny)
			# Removing squeeze and newer scripts
			rm -f "${DIRECTORY}"/*-gdm3
			rm -f "${DIRECTORY}"/*-kaboom
			rm -f "${DIRECTORY}"/*-kde-services
			rm -f "${DIRECTORY}"/*-keyboard-configuration
			;;

		*)
			# Removing lenny legacy scripts
			rm -f "${DIRECTORY}"/*-console-common
			rm -f "${DIRECTORY}"/*-console-setup
			#rm -f "${DIRECTORY}"/*-gdm
			rm -f "${DIRECTORY}"/*-kpersonalizer
			;;
		esac
		;;
esac
