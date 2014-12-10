{% from 'mysql/map.jinja' import mysql with context %}
{% set mysql_root_pass = salt['pillar.get']('mysql:server:root_password', 'mysqlroot') %}

include:
  - mysql.install
  - mysql.service

{% if salt['pillar.get']('mysql:server:install') %}
mysql_server_change_root_password:
  cmd.run:
    - name: /usr/bin/mysqladmin -u root password '{{ mysql_root_pass }}'
    - unless: /usr/bin/mysqladmin -u root --password={{ mysql_root_pass }} version
    - require:
      - sls: mysql.install
      - sls: mysql.service

mysql_server_delete_test_db:
  mysql_database.absent:
    - name: test
    - host: localhost
    - connection_host: localhost
    - connection_port: 3306
    - connection_user: root
    - connection_pass: {{ mysql_root_pass }}
    - connection_charset: utf8
    - require:
      - sls: mysql.install
      - sls: mysql.service
{% endif %}