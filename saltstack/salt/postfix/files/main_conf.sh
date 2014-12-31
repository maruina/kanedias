#!/bin/bash

echo "{{ salt['pillar.get']('postfix:fqdn') }}" > /etc/mailname
postconf -e mydomain={{ salt['pillar.get']('postfix:fqdn') }}
postconf -e mydestination="$myhostname, localhost, localhost.localdomain, localhost.$myhostname"
postconf -e myhostname={{ salt['pillar.get']('postfix:fqdn') }}

postconf -e virtual_transport=dovecot
postconf -e dovecot_destination_recipient_limit=1

postconf -e inet_protocols=all

postconf -e smtpd_banner={{ salt['pillar.get']('postfix:fqdn') }}