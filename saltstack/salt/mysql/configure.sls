{% from 'mysql/map.jinja' import mysql with context %}
{% set mysql_root_pass = salt['pillar.get']('mysql:server:root_password', 'mysqlroot') %}

{% if salt['pillar.get']('mysql:server:install') %}
    mysql_server_change_root_password:
      cmd.run:
        - name: /usr/bin/mysqladmin -u root password '{{ mysql_root_pass }}'

    mysql_server_delete_test_db:

{% endif %}