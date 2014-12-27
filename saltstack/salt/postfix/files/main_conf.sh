#!/bin/bash

echo "{{ salt['pillar.get']('postfix:fqdn') }}" > /etc/mailname

postconf -e virtual_transport=dovecot
postconf -e dovecot_destination_recipient_limit=1