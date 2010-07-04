#!/bin/sh

# Asterisk Startup Helper for Freetz/FRITZ!Box
# Copyright (C) 2009-2010 Thilo-Alexander Ginkel <thilo@ginkel.com>
#
# For instructions, refer to:
# http://blog.ginkel.com/2009/12/running-asterisk-on-a-fritzbox-7270/
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

debug=

while [ $# -gt 0 ]
do
    case "$1" in
        --debug)  debug=yes;;
	--)	shift; break;;
	-*)
	    echo >&2 \
	    "usage: `basename $0` [--debug]"
	    exit 1;;
	*)  break;;	# terminate while loop
    esac
    shift
done

if [ ! -d /var/mod/usr/local ]
then
	mkdir /var/mod/usr/local
fi

if [ ! -d /var/mod/usr/local/asterisk ]
then
        mkdir /var/mod/usr/local/asterisk

	abspath="$(cd "${0%/*}" 2>/dev/null; echo "$PWD"/"${0##*/}")"
	my_dir=`dirname "$abspath"`

        mount --bind $my_dir/../ /var/mod/usr/local/asterisk
        ln -s /var/mod/usr/local/asterisk/sbin/asterisk /var/mod/sbin/
fi

if [ "$debug" = "yes" ]
then
	/var/mod/usr/local/asterisk/sbin/asterisk -vvvdddf
else
	/var/mod/usr/local/asterisk/sbin/safe_asterisk > /dev/null &
fi
