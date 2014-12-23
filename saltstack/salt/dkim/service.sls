{% from 'dkim/map.jinja' import dkim with context %}

include:
  - dkim.install

dkim_service:
  service.running:
    - name: {{ dkim.lookup.service }}
    - enable: True
    - reload: True
    - require:
      - sls: dkim.install