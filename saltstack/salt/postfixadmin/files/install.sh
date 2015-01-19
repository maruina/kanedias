#! /bin/sh
set -e

dest_dir={{ salt['pillar.get']('postfixadmin:root_dir') }}


# Check if I have the source
if [ -f /root/postfixadmin.tar ] ; then
    echo "Postfix Admin TAR found, skip download"
else
    wget http://downloads.sourceforge.net/project/postfixadmin/postfixadmin/postfixadmin-2.92/postfixadmin-2.92.tar.gz -O postfixadmin.tar.gz
    gzip -d postfixadmin.tar.gz
fi

if test "$(ls -A "${dest_dir}")"; then
    echo "Postfix Admin alreay installed, skip installation"
else
    tar -xf postfixadmin.tar --strip-components=1 -C {{ salt['pillar.get']('postfixadmin:root_dir') }}/
    chown -R {{ salt['pillar.get']('postfixadmin:user') }}:{{ salt['pillar.get']('postfixadmin:group') }} {{ salt['pillar.get']('postfixadmin:root_dir') }}
    chmod -R 744 {{ salt['pillar.get']('postfixadmin:root_dir') }}
fi