{% from 'mysql/map.jinja' import mysql with context %}
{% set mysql_root_pass = salt['pillar.get']('mysql:server:root_password', 'mysqlroot') %}

# {% for database in salt['pillar.get']('mysql:database', []) %}
# {% set state_id = 'mysql_db_' ~ loop.index0 %}