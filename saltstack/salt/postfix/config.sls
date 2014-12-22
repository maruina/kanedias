{% from 'postfix/map.jinja' import postfix with context %}

mysql_virtual_mailbox_domains_conf:
  file.managed:
    - name: {{ postfix.lookup.conf_dir }}/mysql-virtual-mailbox-domains.cf
    - source: salt://postfix/files/mysql-virtual-mailbox-domains.cf
    - user: root
    - group: root
    - mode: 622
    - template: jinja
{#    - watch_in:#}
{#      - service: postfix_service#}
{#    - context:#}
{#        parameters: {{ parameters }}#}

mysql_virtual_mailbox_domains_conf_add:
  cmd.run:
    - name: postconf -e virtual_mailbox_domains=mysql:{{ postfix.lookup.conf_dir }}/mysql-virtual-mailbox-domains.cf



