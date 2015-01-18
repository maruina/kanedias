#! /bin/sh
set -e

dest_dir={{ salt['pillar.get']('roundcube:root_dir') }}


# Check if I have the source
if [ -f /root/roundcubemail.tar ] ; then
    echo "Roundcube TAR found, skip download"
else
    wget http://downloads.sourceforge.net/project/roundcubemail/roundcubemail/1.0.4/roundcubemail-1.0.4.tar.gz -O roundcubemail.tar.gz
    gzip -d roundcubemail.tar.gz
fi

if test "$(ls -A "${dest_dir}")"; then
    echo "Roundcube alreay installed, skip installation"
else
    tar -xf roundcubemail.tar --strip-components=1 -C {{ salt['pillar.get']('roundcube:root_dir') }}/
    chown -R {{ salt['pillar.get']('roundcube:user') }}:{{ salt['pillar.get']('roundcube:group') }} {{ salt['pillar.get']('roundcube:root_dir') }}
    chmod -R 744 {{ salt['pillar.get']('roundcube:root_dir') }}
fi