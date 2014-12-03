{% from 'supervisor/map.jinja' import supervisor with context %}

include:
  - supervisor.install

supervisor_service:
  service.running:
    - name: {{ supervisor.lookup.service }}
    - enable: True
    - reload: True
    - require:
      - sls: supervisor.install