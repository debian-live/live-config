#!/bin/sh

set -e

# Defaults
HOST="debian"
USERNAME="user"
USER_FULLNAME="Live user"

Cmdline ()
{
	for PARAMETER in $(cat /proc/cmdline)
	do
		case "${PARAMETER}" in
			live-config)
				# Run all scripts
				SCRIPTS="$(ls /lib/live/config/*)"
				;;

			live-config=*)
				# Only run requested scripts
				OPTIONS="${PARAMETER#live-config=}"
				;;

			# 001-hostname
			live-config.hostname=*)
				HOST="${PARAMETER#live-config.hostname=}"
				;;

			# 003-tzdata
			live-config.timezone=*)
				TIMEZONE="${PARAMETER#live-config.timezone=}"
				;;

			live-config.utc=*)
				UTC="${PARAMETER#live-config.utc=}"
				;;

			# 004-user-setup
			live-config.username=*)
				USERNAME="${PARAMETER#live-config.username=}"
				;;

			live-config.user-fullname=*)
				USER_FULLNAME="${PARAMETER#live-config.user-fullname=}"
				;;

			# 005-locales
			live-config.locales=*)
				LOCALES="${PARAMETER#live-config.locales=}"
				;;

			# 999-hook
			live-config.hook=*)
				HOOK="${PARAMETER#live-config.hook=}"
				;;

		esac
	done

	# Assemble scripts selection
	if [ -z "${SCRIPTS}" ] && [ "${OPTIONS}" != "none" ]
	then
		for OPTION in $(echo ${OPTIONS} | sed -e 's|,| |g')
		do
			SCRIPTS="${SCRIPTS} $(ls /lib/live/config/???-${OPTION})"
		done
	fi
}

Trap ()
{
	RETURN="${?}"

	case "${RETURN}" in
		0)

			;;

		*)
			echo ":ERROR"
			;;
	esac

	return ${RETURN}
}

Main ()
{
	if ! grep -qs "boot=live" /proc/cmdline
	then
		exit 0
	fi

	echo -n "live-config:"
	trap 'Trap' EXIT HUP INT QUIT TERM

	# Reading configuration file from filesystem
	if [ -e /etc/live/config.conf ]
	then
		. /etc/live/config.conf
	fi

	if ls /etc/live/config.conf.d/* > /dev/null 2>&1
	then
		for FILE in /etc/live/config.conf.d/*
		do
			. ${FILE}
		done
	fi

	# Reading configuration file from live-media
	if [ -e /live/image/live/config.conf ]
	then
		. /live/image/live/config.conf
	fi

	if ls /live/image/live/config.conf.d/* > /dev/null 2>&1
	then
		for FILE in /live/image/live/config.conf.d/*
		do
			. ${FILE}
		done
	fi

	# Reading kernel command line
	Cmdline

	# Configuring system
	for SCRIPT in ${SCRIPTS}
	do
		. ${SCRIPT}
	done

	echo "."
}

Main
