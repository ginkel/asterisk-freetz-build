#!/bin/bash

# Asterisk Build Helper for Freetz/FRITZ!Box
# Copyright (C) 2009 Thilo-Alexander Ginkel <thilo@ginkel.com>
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

#
# configuration
# adjust FREETZ_TOOLCHAIN to point to your Freetz toolchain/target directory
#
FREETZ_TOOLCHAIN=
ASTERISK_DOWNLOAD_URL="http://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-1.6.0.19.tar.gz"
CHAN_CAPI_DOWNLOAD_URL="ftp://ftp.chan-capi.org/chan-capi/chan_capi-1.1.4.tar.gz"

#
# DO NOT CHANGE ANY CODE BELOW THIS LINE
#

# exit on error
set -e

#
# sanity checks
#

if [ -z ${FREETZ_TOOLCHAIN} ]
then
	echo "You need to configure the FREETZ_TOOLCHAIN location before running this script"
	exit -1
fi

if [ ! -d ${FREETZ_TOOLCHAIN} ]
then
        echo "FREETZ_TOOLCHAIN (= ${FREETZ_TOOLCHAIN}) is not pointing to a directory"
        exit -1
fi

# include cross-compilation toolchain in path
if [ -x "${FREETZ_TOOLCHAIN}/bin/mipsel-linux-gcc" ]
then
	PATH=${FREETZ_TOOLCHAIN}/bin:${PATH}
else
	if [ -x "${FREETZ_TOOLCHAIN}/mipsel-linux-gcc" ]
	then
		PATH=${FREETZ_TOOLCHAIN}:${PATH}
	else
		echo "Could not locate cross-compiler tollchain in FREETZ_TOOLCHAIN directory (${FREETZ_TOOLCHAIN})"
		exit -1
	fi
fi

# determine script directory
abspath="$(cd "${0%/*}" 2>/dev/null; echo "$PWD"/"${0##*/}")"
my_dir=`dirname "$abspath"`
echo "Build directory: $my_dir"

if [ ! -d "$my_dir/build" ]
then
	mkdir "$my_dir/build"
fi

if [ ! -d "$my_dir/archives" ]
then
        mkdir "$my_dir/archives"
fi

#
# fetch archives
#
pushd "$my_dir/archives"

# download asterisk
asterisk_tar=`basename ${ASTERISK_DOWNLOAD_URL}`
asterisk_dir=`basename ${ASTERISK_DOWNLOAD_URL} .tar.gz`
if [ ! -e $asterisk_tar ]
then
	wget ${ASTERISK_DOWNLOAD_URL}
fi

# download chan_capi
chancapi_tar=`basename ${CHAN_CAPI_DOWNLOAD_URL}`
chancapi_dir=`basename ${CHAN_CAPI_DOWNLOAD_URL} .tar.gz`
if [ ! -e $chancapi_tar ]
then
        wget ${CHAN_CAPI_DOWNLOAD_URL}
fi

# set up target tar file name
target_tar="${asterisk_dir}+${chancapi_dir}-freetz.tar.gz"

popd

#
# extract archives
#
pushd "$my_dir/build"
tar xzf "$my_dir/archives/$asterisk_tar"
tar xzf "$my_dir/archives/$chancapi_tar"

#
# apply patches
#
for patch_file in `ls -p $my_dir/patches/*.patch`
do
	patch -p0 < $patch_file
done

#
# build asterisk
#
pushd $asterisk_dir
make distclean
./configure --build=x86_64-linux-gnu --target=mipsel-linux --host=mipsel-linux --prefix=/var/mod/usr/local/asterisk --without-sdl --without-oss
rm -rf "$my_dir/dist"
make install DESTDIR="$my_dir/dist"
popd

#
# build chan_capi
#
pushd $chancapi_dir
make install INSTALL_PREFIX="$my_dir/dist/var/mod/usr/local/asterisk/"
popd

popd

#
# strip binaries
#
set +e
mipsel-linux-strip --strip-unneeded $my_dir/dist/var/mod/usr/local/asterisk/sbin/* 2> /dev/null
set -e
mipsel-linux-strip --strip-unneeded $my_dir/dist/var/mod/usr/local/asterisk/lib/asterisk/modules/*

#
# build tar file
#

if [ -e "$my_dir/$target_tar" ]
then
	rm "$my_dir/$target_tar"
fi

cp "$my_dir/scripts/start-asterisk.sh" "$my_dir/dist/var/mod/usr/local/asterisk/bin/"

fakeroot tar czf "$my_dir/$target_tar" -C "$my_dir/dist/var/mod/usr/local" asterisk/

echo "Building Asterisk + chan_capi finished. Build result is located in $target_tar"
