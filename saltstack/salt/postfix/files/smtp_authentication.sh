#!/bin/sh

postconf -e smtpd_sasl_type=dovecot
postconf -e smtpd_sasl_path=private/auth
postconf -e smtpd_sasl_auth_enable=yes
postconf -e smtpd_tls_security_level=may
postconf -e smtpd_tls_auth_only=yes
postconf -e smtpd_tls_cert_file={{ salt['pillar.get']('postfix:ssl_dir') }}/certs/{{ salt['pillar.get']('postfix:fqdn') }}.crt
postconf -e smtpd_tls_key_file={{ salt['pillar.get']('postfix:ssl_dir') }}/certs/{{ salt['pillar.get']('postfix:fqdn') }}.key

postconf -e smtpd_helo_required=yes
postconf -e smtpd_recipient_restrictions=" \
permit_mynetworks, \
reject_unauth_destination, \
reject_non_fqdn_recipient, \
reject_unlisted_recipien,t \
reject_unknown_recipient_domain, \
reject_unauth_destination"
postconf -e smtpd_sender_restrictions=" \
permit_mynetworks, \
reject_non_fqdn_sender, \
reject_unknown_sender_domain"
postconf -e smtpd_helo_restrictions=" \
permit_mynetworks, \
permit_sasl_authenticated, \
check_helo_access proxy:hash:/etc/postfix/helo_access"
postconf -e smtpd_client_restrictions=" \
permit_mynetworks, \
permit_sasl_authenticated, \
reject_unauth_pipelining, \
reject_rbl_client cbl.abuseat.org, \
reject_rbl_client bl.spamcop.net, \
reject_rbl_client zen.spamhaus.org"