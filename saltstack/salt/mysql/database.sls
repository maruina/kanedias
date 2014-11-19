{% from 'mysql/map.jinja' import mysql with context %}
{% set mysql_root_pass = salt['pillar.get']('mysql:server:root_password', 'mysqlroot') %}

{% for database in salt['pillar.get']('mysql:database') %}
{% set db_state_id = 'mysql_db_' ~ loop.index0 %}
{{ db_state_id }}:
  mysql_database.present:
    - name: {{ database }}
    - host: localhost
        - connection_host: localhost
        - connection_port: 3306
        - connection_user: root
        - connection_pass: {{ mysql_root_pass }}
        - connection_charset: utf8
{% endfor %}