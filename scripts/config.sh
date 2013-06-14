#!/bin/sh

## live-config(7) - System Configuration Scripts
## Copyright (C) 2006-2013 Daniel Baumann <mail@daniel-baumann.ch>
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program. If not, see <http://www.gnu.org/licenses/>.
##
## The complete text of the GNU General Public License
## can be found in /usr/share/common-licenses/GPL-3 file.


set -e

# Defaults
LIVE_HOSTNAME="debian"
LIVE_USERNAME="user"
LIVE_USER_FULLNAME="Debian Live user"
LIVE_USER_DEFAULT_GROUPS="audio cdrom dip floppy video plugdev netdev powerdev scanner bluetooth debian-tor"

DEBIAN_FRONTEND="noninteractive"
DEBIAN_PRIORITY="critical"
DEBCONF_NOWARNINGS="yes"

IP_SEPARATOR="-"
PROC_OPTIONS="onodev,noexec,nosuid"

# Reading configuration files from filesystem and live-media
for _FILE in /etc/live/config.conf /etc/live/config/* \
	     /lib/live/mount/medium/live/config.conf /lib/live/mount/medium/live/config/*
do
	if [ -e "${_FILE}" ]
	then
		. "${_FILE}"
	fi
done

Cmdline ()
{
	for _PARAMETER in ${LIVE_CONFIG_CMDLINE}
	do
		case "${_PARAMETER}" in
			live-config=*|config=*)
				# Only run requested scripts
				LIVE_CONFIGS="${_PARAMETER#*config=}"
				LIVE_NOCONFIGS=""
				LIVE_CONFIG_SCRIPTS=""
				;;

			live-config|config)
				# Run all scripts
				LIVE_CONFIGS=""
				LIVE_NOCONFIGS=""
				LIVE_CONFIG_SCRIPTS="$(ls /lib/live/config/*)"
				;;

			live-noconfig=*|noconfig=*)
				# Don't run requested scripts
				LIVE_CONFIGS=""
				LIVE_NOCONFIGS="${_PARAMETER#*noconfig=}"
				LIVE_CONFIG_SCRIPTS="$(ls /lib/live/config/*)"
				;;

			live-noconfig|noconfig)
				# Don't run any script
				LIVE_CONFIGS=""
				LIVE_NOCONFIGS=""
				LIVE_CONFIG_SCRIPTS=""
				;;

			# Shortcuts
			live-config.noroot|noroot)
				# Disable root access, no matter what mechanism
				LIVE_CONFIG_NOROOT="true"
				;;

			live-config.noautologin|noautologin)
				# Disables both console and graphical autologin.
				LIVE_CONFIG_NOAUTOLOGIN="true"
				;;

			live-config.nottyautologin|nottyautologin)
				# Disables console autologin.
				LIVE_CONFIG_NOTTYAUTOLOGIN="true"
				;;

			live-config.nox11autologin|nox11autologin)
				# Disables graphical autologin, no matter what mechanism
				LIVE_CONFIG_NOX11AUTOLOGIN="true"
				;;

			# Special options
			live-config.debug|debug)
				LIVE_DEBUG="true"
				;;
		esac
	done

	# Exclude shortcuts specific scripts
	case "${LIVE_CONFIG_NOROOT}" in
		true)
			# Disable root access, no matter what mechanism
			LIVE_NOCONFIGS="${LIVE_NOCONFIGS},sudo,policykit"
			;;
	esac

	case "${LIVE_CONFIG_NOAUTOLOGIN}" in
		true)
			# Disables both console and graphical autologin.
			LIVE_NOCONFIGS="${LIVE_NOCONFIGS},gdm,gdm3,lightdm,lxdm,nodm,slim,,xinit"
			;;
	esac

	case "${LIVE_CONFIG_NOX11AUTOLOGIN}" in
		true)
			# Disables graphical autologin, no matter what mechanism
			LIVE_NOCONFIGS="${LIVE_NOCONFIGS},gdm,gdm3,lightdm,lxdm,nodm,slim,xinit"
			;;
	esac

	# Include requested scripts
	if [ -n "${LIVE_CONFIGS}" ]
	then
		for _CONFIG in $(echo ${LIVE_CONFIGS} | sed -e 's|,| |g')
		do
			LIVE_CONFIG_SCRIPTS="${LIVE_CONFIG_SCRIPTS} $(ls /lib/live/config/????-${_CONFIG} 2> /dev/null || true)"
		done
	fi

	# Exclude requested scripts
	if [ -n "${LIVE_NOCONFIGS}" ]
	then
		for _NOCONFIG in $(echo ${LIVE_NOCONFIGS} | sed -e 's|,| |g')
		do
			LIVE_CONFIG_SCRIPTS="$(echo ${LIVE_CONFIG_SCRIPTS} | sed -e "s|$(ls /lib/live/config/????-${_NOCONFIG} 2> /dev/null || echo none)||")"
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

Setup_network ()
{
	if [ -z "${_NETWORK}" ] && [ -e /etc/init.d/live-config ]
	then
		/etc/init.d/mountkernfs.sh start > /dev/null 2>&1
		/etc/init.d/mountdevsubfs.sh start > /dev/null 2>&1
		/etc/init.d/ifupdown-clean start > /dev/null 2>&1
		/etc/init.d/ifupdown start > /dev/null 2>&1
		/etc/init.d/networking start > /dev/null 2>&1

		# Now force adapter up if specified with ethdevice= on cmdline
		if [ -n "${ETHDEVICE}" ]
		then
			ifup --force "${ETHDEVICE}"
		fi

		_NETWORK="true"
		export _NETWORK
	fi
}

Main ()
{
	if [ ! -e /proc/version ]
	then
		mount -n -t proc -o${PROC_OPTIONS} -odefaults proc /proc
	fi

	LIVE_CONFIG_CMDLINE="${LIVE_CONFIG_CMDLINE:-$(cat /proc/cmdline)}"

	if ! echo ${LIVE_CONFIG_CMDLINE} | grep -qs "boot=live"
	then
		exit 0
	fi

	# Setting up log redirection
	rm -f /var/log/live/config.log
	rm -f /var/log/live/config.pipe

	mkdir -p /var/log/live
	mkfifo /var/log/live/config.pipe
	tee < /var/log/live/config.pipe /var/log/live/config.log &
	exec > /var/log/live/config.pipe 2>&1

	echo -n "live-config:" > /var/log/live/config.pipe 2>&1
	trap 'Trap' EXIT HUP INT QUIT TERM

	# Processing command line
	Cmdline

	case "${LIVE_CONFIG_DEBUG}" in
		true)
			set -x
			;;
	esac

	# Configuring system
	LIVE_CONFIG_SCRIPTS="$(echo ${LIVE_CONFIG_SCRIPTS} | sed -e 's| |\n|g' | sort -u)"

	for _SCRIPT in ${LIVE_CONFIG_SCRIPTS}
	do
		[ "${LIVE_CONFIG_DEBUG}" = "true" ] && echo "[$(date +'%F %T')] live-config: ${_SCRIPT}" > /var/log/live/config.pipe

		. ${_SCRIPT} > /var/log/live/config.pipe 2>&1
	done

	echo "." > /var/log/live/config.pipe

	# Cleaning up log redirection
	rm -f /var/log/live/config.pipe
}

Main ${@}
