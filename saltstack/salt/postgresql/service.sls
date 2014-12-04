{% from 'postgresql/map.jinja' import postgresql with context %}

include:
  - postgresql.install

{% if salt['pillar.get']('postgresql:server:install') %}
postgresql_server_service:
  service.running:
    - name: {{ postgresql.lookup.server_service }}
    - enable: True
    - reload: True
    - require:
      - sls: postgresql.install
{% endif %}