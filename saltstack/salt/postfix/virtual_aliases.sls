{% from 'postfix/map.jinja' import postfix with context %}

include:
  - mysql.install
  - mysql.service
  - mysql.database
  - mysql.user

virtual_aliases_sql:
  file.managed:
    - name: {{ postfix.lookup.conf_dir }}/sql_scripts/virtual_aliases.sql
    - source: salt://postfix/files/virtual_aliases.sql
    - user: root
    - group: root
    - makedirs: True
    - mode: 622
    - template: jinja

virtual_aliases_create_table:
  cmd.run:
    - name: mysql --user={{ salt['pillar.get']('postfix:db:user') }} --password={{ salt['pillar.get']('postfix:db:password') }} {{ salt['pillar.get']('postfix:db:database') }}  < {{ postfix.lookup.conf_dir }}/sql_scripts/virtual_aliases.sql
    - unless: test -f /var/lib/mysql/{{ salt['pillar.get']('postfix:db:database') }}/virtual_aliases.frm
    - require:
      - sls: mysql.install
      - sls: mysql.service
      - sls: mysql.database
      - sls: mysql.user

{% for alias in salt['pillar.get']('postfix:alias') %}
    {% set add_alias = 'add_alias_' ~ loop.index0 %}

{{ add_alias }}:
  mysql_query.run:
    - database: {{ salt['pillar.get']('postfix:db:database') }}
    - query: "INSERT INTO `mailserver`.`virtual_aliases` (`domain_id`, `source`, `destination`) SELECT id, '{{ alias[1] }}', '{{ alias[2] }}' FROM `mailserver`.`virtual_domains` where name='{{ alias[0] }}';"
    - connection_host: {{ salt['pillar.get']('postfix:db:host') }}
    - connection_user: {{ salt['pillar.get']('postfix:db:user') }}
    - connection_pass: {{ salt['pillar.get']('postfix:db:password') }}

{% endfor %}