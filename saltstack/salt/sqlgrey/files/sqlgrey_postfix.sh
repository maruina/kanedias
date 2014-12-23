#!/bin/bash

{% if 'tcp' in salt['pillar.get']('sqlgrey:socket:type') %}
sqlgrey_socket="inet:{{ salt['pillar.get']('sqlgrey:socket:host') }}:{{ salt['pillar.get']('sqlgrey:socket:port') }}"
{% elif 'unix' in salt['pillar.get']('sqlgrey:socket:type') %}
sqlgrey_socket="unix:{{ salt['pillar.get']('sqlgrey:socket:file') }}"
{% endif %}

smtpd_recipient_restrictions=`cat {{ salt['pillar.get']('sqlgrey:postfix_main') }}  | grep smtpd_recipient_restrictions`
new_smtpd_recipient_restrictions="$smtpd_recipient_restrictions, $sqlgrey_socket"
sed -i "s/smtpd_recipient_restrictions.*$/$new_smtpd_recipient_restrictions/g" {{ salt['pillar.get']('sqlgrey:postfix_main') }}

service postfix restart
