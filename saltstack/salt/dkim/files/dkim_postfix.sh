#!/bin/bash

postconf -e milter_protocol=2
postconf -e milter_default_action=accept

{% if 'tcp' in salt['pillar.get']('dkim:socket:type') %}
postconf -e smtpd_milters=inet:{{ salt['pillar.get']('dkim:socket:host') }}:{{ salt['pillar.get']('dkim:socket:port') }}
postconf -e non_smtpd_milters=inet:{{ salt['pillar.get']('dkim:socket:host') }}:{{ salt['pillar.get']('dkim:socket:port') }}
{% elif 'unix' in salt['pillar.get']('dkim:socket:type')
postconf -e smtpd_milters=unix:{{ salt['pillar.get']('dkim:socket:file') }}
postconf -e non_smtpd_milters=unix:{{ salt['pillar.get']('dkim:socket:file') }}
{% endif %}

