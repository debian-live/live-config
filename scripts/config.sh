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
				CONFIGS="${PARAMETER#live-config=}"
				;;

			live-noconfig)
				# Don't run any script
				SCRIPTS=""
				;;

			live-noconfig=*)
				# Don't run requested scripts
				SCRIPTS="$(ls /lib/live/config/*)"
				NOCONFIGS="${PARAMETER#live-noconfig=}"
				;;

			# 001-hostname
			live-config.hostname=*)
				HOST="${PARAMETER#live-config.hostname=}"
				;;

			# 002-user-setup
			live-config.username=*)
				USERNAME="${PARAMETER#live-config.username=}"
				;;

			live-config.user-fullname=*)
				USER_FULLNAME="${PARAMETER#live-config.user-fullname=}"
				;;

			# 004-locales
			live-config.locales=*)
				LOCALES="${PARAMETER#live-config.locales=}"
				;;

			# 005-tzdata
			live-config.timezone=*)
				TIMEZONE="${PARAMETER#live-config.timezone=}"
				;;

			live-config.utc=*)
				UTC="${PARAMETER#live-config.utc=}"
				;;

			# 999-hook
			live-config.hook=*)
				HOOK="${PARAMETER#live-config.hook=}"
				;;

			# Shortcuts
			live-config.noroot)
				# Disable root access, no matter what mechanism
				SCRIPTS="${SCRIPTS:-$(ls /lib/live/config/*)}"
				NOCONFIGS="${NOCONFIGS},sudo,policykit"
				;;
		esac
	done

	# Include requested scripts
	if [ -n "${CONFIGS}" ]
	then
		for CONFIG in $(echo ${CONFIGS} | sed -e 's|,| |g')
		do
			SCRIPTS="${SCRIPTS} $(ls /lib/live/config/???-${CONFIG})"
		done
	fi

	# Exclude requested scripts
	if [ -n "${NOCONFIGS}" ]
	then
		for NOCONFIG in $(echo ${NOCONFIGS} | sed -e 's|,| |g')
		do
			SCRIPTS="$(echo ${SCRIPTS} | sed -e "s|$(ls /lib/live/config/???-${NOCONFIG})||")"
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
