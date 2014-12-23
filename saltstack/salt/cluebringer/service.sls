{% from 'cluebringer/map.jinja' import cluebringer with context %}

include:
  - cluebringer.install

cluebringer_service:
  service.running:
    - name: {{ cluebringer.lookup.service }}
    - enable: True
    - reload: True
    - require:
      - sls: cluebringer.install