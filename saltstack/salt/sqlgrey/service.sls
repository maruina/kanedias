{% from 'sqlgrey/map.jinja' import sqlgrey with context %}

include:
  - sqlgrey.install

sqlgrey_service:
  service.running:
    - name: {{ sqlgrey.lookup.service }}
    - enable: True
    - reload: True
    - require:
      - sls: sqlgrey.install