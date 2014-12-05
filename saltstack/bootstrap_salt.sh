#! /bin/sh
set -e

if [ "$1" = "master" ] ; then
    salt_parms="-M -N"
elif [ "$1" = "minion" ] ; then
    salt_parms=""
else
    echo "Error: this script should be passed either 'master' or 'minion' as first parameter"
    exit 1
fi

# Check the OS type
if [ -f /etc/redhat-release ] ; then
    ostype="redhat"
elif [ -f /etc/debian_version ] ; then
    ostype="debian"
else
    echo "Error: unsupported OS detected. Aborting..."
    exit 1
fi

# Check dependencies
salt_call=`command -v salt-call || true`
wget=`command -v wget || true`
if [ -z ${salt_call} ] || [ -z ${wget} ] ; then
    # Check user permissions for software installation
    if [ ! -eq $UID 0 ] ; then
        # We are not root, check for sudo
        sudo=`command -v sudo || true`
        if [ -z ${sudo} ] ; then
            echo "Error: not enough permissions to install the Salt Master"
            exit 1
        fi
    fi

    # Find the package manager and install what's needed
    if [ "${ostype}" = "redhat" ] ; then
        yum=`command -v yum` || { echo "Fatal error: RedHat-like OS detected, but yum could not be found." ; exit 1 ; }

        # TODO: install salt-call on rh/centos

        if [ -z ${wget} ] ; then
            ${sudo} ${yum} install -y wget
        fi
    elif [ "${ostype}" = "debian" ] ; then
        apt_get=`command -v apt-get` || { echo "Fatal error: Debian-like OS detected, but apt-get could not be found." ; exit 1 ; }

        if [ -z ${salt_call} ] ; then
            ${sudo} ${apt_get} install -y --no-install-recommends salt-common
        fi

        if [ -z ${wget} ] ; then
            ${sudo} ${apt_get} install -y --no-install-recommends wget
        fi
    fi
fi

wget -O ${HOME}/install_salt.sh https://bootstrap.saltstack.com
sudo sh ${HOME}/install_salt.sh ${salt_parms}
