#!/bin/bash
set -e

# Check the OS type
if [ -f /etc/redhat-release ] ; then
    ostype="redhat"
elif [ -f /etc/debian_version ] ; then
    ostype="debian"
else
    echo "Error: unsupported OS detected. Aborting..."
    exit 1
fi

# Check user permissions for software installation
if [ `id -u` -ne 0 ] ; then
    # We are not root, check for sudo
    sudo=`command -v sudo || true`
    if [ -z ${sudo} ] ; then
        echo "Error: not enough permissions to install the Salt Master"
        exit 1
    fi
fi

wget=`command -v wget || true`
gzip=`command -v gzip || true`

# Find the package manager and install what's needed
if [ "${ostype}" = "redhat" ] ; then
    yum=`command -v yum` || { echo "Fatal error: RedHat-like OS detected, but yum could not be found." ; exit 1 ; }

    if [ -z ${wget} ] ; then
        ${sudo} ${yum} install -y wget
    fi
    if [ -z ${gzip} ] ; then
        ${sudo} ${yum} install -y gzip
    fi
elif [ "${ostype}" = "debian" ] ; then
    apt_get=`command -v apt-get` || { echo "Fatal error: Debian-like OS detected, but apt-get could not be found." ; exit 1 ; }

    if [ -z ${wget} ] ; then
        ${sudo} ${apt_get} install -y --no-install-recommends wget
    fi
    if [ -z ${gzip} ] ; then
        ${sudo} ${apt_get} install -y --no-install-recommends gzip
    fi
fi

source_dir={{ salt['pillar.get']('asterisk:source_dir') }}

# Check if I have the source
if [ -f ${source_dir}/asterisk.tar ] ; then
    echo "Asterisk TAR found, skip download"
else
    ${sudo} wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz -O ${source_dir}/asterisk.tar.gz
    ${sudo} gzip -d ${source_dir}/asterisk.tar.gz
fi
if [ -d ${source_dir}/asterisk ] ; then
    echo "Asterisk installed, skip installation"
else
    ${sudo} tar -xf ${source_dir}/asterisk.tar --strip-components=1 -C ${source_dir}/asterisk/
    ${sudo} chown -R {{ user }}:{{ user }} ${source_dir}/asterisk
    ${sudo} chmod -R 744 ${source_dir}/asterisk
    cd ${source_dir}/asterisk
    ${sudo} ./configure
    ${sudo} make
    ${sudo} make install
    ${sudo} chown -R {{ user }}:{{ user }} /var/lib/asterisk/
    ${sudo} chown -R {{ user }}:{{ user }} /var/spool/asterisk/
    ${sudo} chown -R {{ user }}:{{ user }} /var/log/asterisk/
    ${sudo} chown -R {{ user }}:{{ user }} /var/run/asterisk/
fi

