{% from 'postgresql/map.jinja' import postgresql with context %}

{% for db in salt['pillar.get']('postgresql:server:postgis_db') %}

install_postgis_{{ db }}:
  postgres_extension.present:
    - name: postgis
    - maintenance_db: {{ db }}
    - require:
      - service: {{ postgresql.lookup.server_service }}

install_postgis_topology_{{ db }}:
  postgres_extension.present:
    - name: postgis_topology
    - maintenance_db: {{ db }}
    - require:
      - service: {{ postgresql.lookup.server_service }}

{% endfor %}