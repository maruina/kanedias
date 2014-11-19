{% from 'mysql/map.jinja' import mysql with context %}
{% set mysql_root_pass = salt['pillar.get']('mysql:server:root_password', 'mysqlroot') %}

include:
  - mysql.install

{% if salt['pillar.get']('mysql:server:install') %}
    mysql_server_change_root_password:
      cmd.run:
        - name: /usr/bin/mysqladmin -u root password '{{ mysql_root_pass }}'
        - require:
          - sls: mysql.install

    mysql_server_delete_test_db:
      mysql_database.absent:
        - name: test
        - host: localhost
        - connection_host: localhost
        - connection_port: 3306
        - connection_user: root
        - connection_pass: {{ mysql_root_pass }}
        - connection_charset: utf8
{% endif %}