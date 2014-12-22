{% from 'postfix/map.jinja' import postfix with context %}

include:
  - mysql.install
  - mysql.service
  - mysql.database
  - mysql.user

virtual_domains_sql:
  file.managed:
    - name: {{ postfix.lookup.conf_dir }}/sql_scripts/virtual_domains.sql
    - source: salt://postfix/files/virtual_domains.sql
    - user: root
    - group: root
    - makedirs: True
    - mode: 622
    - template: jinja

virtual_domains_create_table:
  cmd.run:
    - name: mysql --user={{ salt['pillar.get']('postfix:db:user') }} --password={{ salt['pillar.get']('postfix:db:password') }} {{ salt['pillar.get']('postfix:db:database') }}  < {{ postfix.lookup.conf_dir }}/sql_scripts/virtual_domains.sql
    - unless: test -f /var/lib/mysql/{{ salt['pillar.get']('postfix:db:database') }}/virtual_domains.frm
    - require:
      - sls: mysql.install
      - sls: mysql.service
      - sls: mysql.database
      - sls: mysql.user

{% for domain in salt['pillar.get']('postfix:domain') %}
    {% set add_domain = 'add_domain_' ~ domain %}

{{ add_domain }}:
  mysql_query.run:
    - database: {{ salt['pillar.get']('postfix:db:database') }}
    - query: "INSERT INTO `{{ salt['pillar.get']('postfix:db:database') }}`.`virtual_domains` (`name`) VALUES ('{{ domain }}');"
    - connection_host: {{ salt['pillar.get']('postfix:db:host') }}
    - connection_user: {{ salt['pillar.get']('postfix:db:user') }}
    - connection_pass: {{ salt['pillar.get']('postfix:db:password') }}

{% endfor %}