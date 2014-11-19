{% from 'mysql/map.jinja' import mysql with context %}

include:
  - mysql.install

{% if salt['pillar.get']('mysql:server:install') %}
mysql_server_service:
  service.running:
    - name: {{ mysql.lookup.server_service }}
    - enable: True
    - reload: True
    - require:
      - sls: mysql.install
{% endif %}