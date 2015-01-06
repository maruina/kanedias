#!/bin/bash

echo "{{ salt['pillar.get']('postfix:host') }}" > /etc/mailname
postconf -e mydomain={{ salt['pillar.get']('postfix:mail_domain') }}
postconf -e myhostname={{ salt['pillar.get']('postfix:host') }}

postconf -e virtual_transport=dovecot
postconf -e dovecot_destination_recipient_limit=1

postconf -e inet_protocols=all

postconf -e smtpd_banner="$myhostname ESMTP $mail_name ($mail_version)"