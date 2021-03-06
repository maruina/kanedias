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

mysql_virtual_sender_maps_conf:
  file.managed:
    - name: {{ postfix.lookup.conf_dir }}/mysql-virtual-sender-maps.cf
    - source: salt://postfix/files/mysql-virtual-sender-maps.cf
    - user: root
    - group: root
    - mode: 622
    - template: jinja

mysql_virtual_sender_maps_conf_add:
  cmd.run:
    - name: postconf -e smtpd_sender_login_maps=mysql:{{ postfix.lookup.conf_dir }}/mysql-virtual-sender-maps.cf

postfix_main_conf:
  cmd.script:
    - name: main_conf.sh
    - source: salt://postfix/files/main_conf.sh
    - user: root
    - group: root
    - template: jinja

postfix_helo_access_conf:
  file.managed:
    - name: {{ postfix.lookup.conf_dir }}/helo_access
    - source: salt://postfix/files/helo_access
    - user: root
    - group: root
    - mode: 644
    - template: jinja

postfix_helo_access:
  cmd.run:
    - name: postmap {{ postfix.lookup.conf_dir }}/helo_access

postfix_helo_access_db:
  file.managed:
    - name: {{ postfix.lookup.conf_dir }}/helo_access.db
    - user: root
    - group: root
    - mode: 644

postfix_master_conf:
  file.managed:
    - name: {{ postfix.lookup.conf_dir }}/master.cf
    - source: salt://postfix/files/master.cf
    - user: root
    - group: root
    - mode: 622
    - template: jinja
    - watch_in:
      - service: postfix_service

postfix_smtp_authentication:
  cmd.script:
    - name: smtp_authentication.sh
    - source: salt://postfix/files/smtp_authentication.sh
    - user: root
    - group: root
    - template: jinja