#!/bin/sh

set -e

# Defaults
LIVE_HOSTNAME="debian"
LIVE_USERNAME="user"
LIVE_USER_FULLNAME="Debian Live user"

Cmdline ()
{
	for _PARAMETER in $(cat /proc/cmdline)
	do
		case "${_PARAMETER}" in
			live-config)
				# Run all scripts
				_SCRIPTS="$(ls /lib/live/config/*)"
				;;

			live-config=*)
				# Only run requested scripts
				LIVE_CONFIGS="${_PARAMETER#live-config=}"
				;;

			live-noconfig)
				# Don't run any script
				_SCRIPTS=""
				;;

			live-noconfig=*)
				# Don't run requested scripts
				_SCRIPTS="$(ls /lib/live/config/*)"
				LIVE_NOCONFIGS="${_PARAMETER#live-noconfig=}"
				;;

			# 001-hostname
			live-config.hostname=*)
				LIVE_HOSTNAME="${_PARAMETER#live-config.hostname=}"
				;;

			# 002-user-setup
			live-config.username=*)
				LIVE_USERNAME="${_PARAMETER#live-config.username=}"
				;;

			live-config.user-fullname=*)
				LIVE_USER_FULLNAME="${_PARAMETER#live-config.user-fullname=}"
				;;

			# 004-locales
			live-config.locales=*)
				LIVE_LOCALES="${_PARAMETER#live-config.locales=}"
				;;

			# 005-tzdata
			live-config.timezone=*)
				LIVE_TIMEZONE="${_PARAMETER#live-config.timezone=}"
				;;

			live-config.utc=*)
				LIVE_UTC="${_PARAMETER#live-config.utc=}"
				;;

			# 999-hook
			live-config.hook=*)
				LIVE_HOOK="${_PARAMETER#live-config.hook=}"
				;;

			# Shortcuts
			live-config.noroot)
				# Disable root access, no matter what mechanism
				_SCRIPTS="${_SCRIPTS:-$(ls /lib/live/config/*)}"
				LIVE_NOCONFIGS="${LIVE_NOCONFIGS},sudo,policykit"
				;;

			live-config.noxlogin)
				# Disables graphical autologin, no matter what
				# mechanism
				_SCRIPTS="${_SCRIPTS:-$(ls /lib/live/config/*)}"
				LIVE_NOCONFIGS="${LIVE_NOCONFIGS},gdm,gdm3,kdm,lxdm,nodm"
				;;
		esac
	done

	# Include requested scripts
	if [ -n "${LIVE_CONFIGS}" ]
	then
		for LIVE_CONFIG in $(echo ${LIVE_CONFIGS} | sed -e 's|,| |g')
		do
			_SCRIPTS="${_SCRIPTS} $(ls /lib/live/config/???-${LIVE_CONFIG})"
		done
	fi

	# Exclude requested scripts
	if [ -n "${LIVE_NOCONFIGS}" ]
	then
		for LIVE_NOCONFIG in $(echo ${LIVE_NOCONFIGS} | sed -e 's|,| |g')
		do
			_SCRIPTS="$(echo ${_SCRIPTS} | sed -e "s|$(ls /lib/live/config/???-${LIVE_NOCONFIG})||")"
		done
	fi
}

Trap ()
{
	_RETURN="${?}"

	case "${_RETURN}" in
		0)

			;;

		*)
			echo ":ERROR"
			;;
	esac

	return ${_RETURN}
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
		for _FILE in /etc/live/config.conf.d/*
		do
			. ${_FILE}
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
			. ${_FILE}
		done
	fi

	# Reading kernel command line
	Cmdline

	# Configuring system
	for _SCRIPT in ${_SCRIPTS}
	do
		. ${_SCRIPT}
	done

	echo "."
}

Main
