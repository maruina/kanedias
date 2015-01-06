#!/bin/sh

postconf -e smtpd_sasl_type=dovecot
postconf -e smtpd_sasl_path=private/auth
postconf -e smtpd_sasl_auth_enable=yes
postconf -e broken_sasl_auth_clients=yes
postconf -e smtpd_sasl_security_options="noanonymous, noplaintext"
postconf -e smtpd_sasl_authenticated_header=no

postconf -e smtpd_sasl_tls_security_options=noanonymous
postconf -e smtpd_tls_auth_only=yes

postconf -e smtpd_tls_security_level=may
postconf -e smtpd_tls_auth_only=yes
postconf -e smtpd_tls_cert_file={{ salt['pillar.get']('postfix:ssl_dir') }}/certs/{{ salt['pillar.get']('postfix:host') }}.crt
postconf -e smtpd_tls_key_file={{ salt['pillar.get']('postfix:ssl_dir') }}/certs/{{ salt['pillar.get']('postfix:host') }}.key

postconf -e proxy_read_maps="\
proxy:hash:/etc/postfix/helo_access,\
proxy:unix:passwd.byname"

postconf -e smtpd_data_restrictions=reject_unauth_pipelining
postconf -e smtpd_reject_unlisted_recipient=yes
postconf -e smtpd_reject_unlisted_sender=yes
postconf -e smtpd_helo_required=yes
postconf -e smtpd_recipient_restrictions="\
  permit_mynetworks,\
  permit_sasl_authenticated,\
  reject_unknown_sender_domain,\
  reject_unknown_recipient_domain,\
  reject_non_fqdn_recipient,\
  reject_non_fqdn_sender,\
  reject_unlisted_recipient,\
  reject_unauth_destination"
postconf -e smtpd_sender_restrictions="\
  permit_mynetworks,\
  permit_sasl_authenticated,\
  reject_non_fqdn_sender,\
  reject_unknown_sender_domain,\
  reject_sender_login_mismatch"
postconf -e smtpd_helo_restrictions="\
  permit_mynetworks,\
  permit_sasl_authenticated,\
  reject_non_fqdn_helo_hostname,\
  reject_invalid_helo_hostname,\
  check_helo_access proxy:hash:/etc/postfix/helo_access"
postconf -e smtpd_client_restrictions="\
  permit_mynetworks,\
  permit_sasl_authenticated,\
  reject_unauth_pipelining,\
  reject_rbl_client cbl.abuseat.org,\
  reject_rbl_client bl.spamcop.net,\
  reject_rbl_client zen.spamhaus.org"