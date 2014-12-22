{% from 'postfix/map.jinja' import postfix with context %}

mysql_virtual_mailbox_domains_conf:
  file.managed:
    - name: {{ postfix.lookup.conf_dir }}/mysql-virtual-mailbox-domains.cf
    - source: salt://postfix/files/mysql-virtual-mailbox-domains.cf
    - user: root
    - group: root
    - mode: 622
    - template: jinja

mysql_virtual_mailbox_domains_conf_add:
  cmd.run:
    - name: postconf -e virtual_mailbox_domains=mysql:{{ postfix.lookup.conf_dir }}/mysql-virtual-mailbox-domains.cf

mysql_virtual_mailbox_maps_conf:
  file.managed:
    - name: {{ postfix.lookup.conf_dir }}/mysql-virtual-mailbox-maps.cf
    - source: salt://postfix/files/mysql-virtual-mailbox-maps.cf
    - user: root
    - group: root
    - mode: 622
    - template: jinja

mysql_virtual_mailbox_maps_conf_add:
  cmd.run:
    - name: postconf -e virtual_mailbox_maps=mysql:{{ postfix.lookup.conf_dir }}/mysql-virtual-mailbox-maps.cf

mysql_virtual_alias_maps_conf:
  file.managed:
    - name: {{ postfix.lookup.conf_dir }}/mysql-virtual-alias-maps.cf
    - source: salt://postfix/files/mysql-virtual-alias-maps.cf
    - user: root
    - group: root
    - mode: 622
    - template: jinja

mysql_virtual_alias_maps_conf_add:
  cmd.run:
    - name: postconf -e virtual_alias_maps=mysql:{{ postfix.lookup.conf_dir }}/mysql-virtual-alias-maps.cf

postfix_conf:
  file.managed:
    - name: {{ postfix.lookup.conf_dir }}/master.cf
    - source: salt://postfix/files/master.cf
    - user: root
    - group: root
    - mode: 622
    - template: jinja
    - watch_in:
      - service: postfix_service

postfix_virtual_transport:
  cmd.run:
    - name: postconf -e virtual_transport=dovecot

postfix_dovecot_destination_recipient_limit:
  cmd.run:
    - name: postconf -e dovecot_destination_recipient_limit=1