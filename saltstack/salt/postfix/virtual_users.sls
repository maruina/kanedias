{% from 'postfix/map.jinja' import postfix with context %}

include:
  - mysql.install
  - mysql.service
  - mysql.database
  - mysql.user

virtual_users_sql:
  file.managed:
    - name: {{ postfix.lookup.conf_dir }}/sql_scripts/virtual_users.sql
    - source: salt://postfix/files/virtual_users.sql
    - user: root
    - group: root
    - makedirs: True
    - mode: 622
    - template: jinja

virtual_users_create_table:
  cmd.run:
    - name: mysql --user={{ salt['pillar.get']('postfix:db:user') }} --password={{ salt['pillar.get']('postfix:db:password') }} {{ salt['pillar.get']('postfix:db:database') }}  < {{ postfix.lookup.conf_dir }}/sql_scripts/virtual_users.sql
    - unless: test -f /var/lib/mysql/{{ salt['pillar.get']('postfix:db:database') }}/virtual_users.frm
    - require:
      - sls: mysql.install
      - sls: mysql.service
      - sls: mysql.database
      - sls: mysql.user

{% for user, parameters in salt['pillar.get']('postfix:user').iteritems() %}
    {% set add_user = 'add_user_' ~ user %}

{{ add_user }}:
  mysql_query.run:
    - database: {{ salt['pillar.get']('postfix:db:database') }}
    - query: "INSERT INTO `mailserver`.`virtual_users` (`domain_id`, `password`, `email`) SELECT id, MD5( '{{ parameters['password'] }}' ), '{{ user }}@{{ parameters['domain'] }}' FROM `mailserver`.`virtual_domains` where name='{{ parameters['domain'] }}';"
    - connection_host: {{ salt['pillar.get']('postfix:db:host') }}
    - connection_user: {{ salt['pillar.get']('postfix:db:user') }}
    - connection_pass: {{ salt['pillar.get']('postfix:db:password') }}

{% endfor %}