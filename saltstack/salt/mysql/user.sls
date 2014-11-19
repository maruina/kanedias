{% from 'mysql/map.jinja' import mysql with context %}
{% set mysql_root_pass = salt['pillar.get']('mysql:server:root_password', 'mysqlroot') %}

{% for name, user in salt['pillar.get']('mysql:user', {}).items() %}
{% set user_state_id = 'mysql_user_' ~ loop.index0 %}
{{ user_state_id }}:
  mysql_user.present:
    - name: {{ name }}
    - host: {{ user.host }}
    - password: {{ user.password }}
    - connection_host: localhost
    - connection_port: 3306
    - connection_user: root
    - connection_pass: {{ mysql_root_pass }}
    - connection_charset: utf8
    - saltenv:
      - LC_ALL: "en_US.utf8"


    {% for db in user['databases'] %}
    {% set privileges_state_id = name ~ '_privileges_' ~ loop.index0 %}:
    {{ privileges_state_id }}:
  mysql_grants.present:
    - name: {{ name ~ '_' ~ db['database'] ~ '_' ~ db['table'] | default('all') }}
    - grant: {{db['grants']|join(",")}}
    - database: '{{ db['database'] }}.{{ db['table'] | default('*') }}'
    - grant_option: {{ db['grant_option'] | default(False) }}
    - user: {{ name }}
    - host: '{{ user['host'] }}'
    - connection_host: localhost
    - connection_port: 3306
    - connection_user: root
    - connection_pass: {{ mysql_root_pass }}
    - connection_charset: utf8
    {% endfor %}

{% endfor %}