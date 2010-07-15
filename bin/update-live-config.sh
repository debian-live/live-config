#!/bin/sh

set -e

_DIRECTORY="${1:-/lib/live/config}"

if [ ! -e "${_DIRECTORY}" ]
then
	echo "E: ${_DIRECTORY} - not found."
	exit 1
fi

_DISTRIBUTION="$(lsb_release -is | tr [A-Z] [a-z])"
_RELEASE="$(lsb_release -cs | tr [A-Z] [a-z])"

echo "Removing unused scripts..."

case "${_DISTRIBUTION}" in
	debian)
		# Removing ubuntu scripts
		rm -f "${_DIRECTORY}"/*-apport

		case "${_RELEASE}" in
		lenny)
			# Removing squeeze and newer scripts
			rm -f "${_DIRECTORY}"/*-gdm3
			rm -f "${_DIRECTORY}"/*-kaboom
			rm -f "${_DIRECTORY}"/*-kde-services
			rm -f "${_DIRECTORY}"/*-keyboard-configuration
			;;

		*)
			# Removing lenny legacy scripts
			rm -f "${_DIRECTORY}"/*-console-common
			rm -f "${_DIRECTORY}"/*-console-setup
			#rm -f "${_DIRECTORY}"/*-gdm
			rm -f "${_DIRECTORY}"/*-kpersonalizer
			;;
		esac
		;;
esac
