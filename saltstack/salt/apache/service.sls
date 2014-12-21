{% from 'apache/map.jinja' import apache with context %}

include:
  - apache.install

apache_service:
  service.running:
    - name: {{ apache.lookup.service }}
    - enable: True
    - reload: True
    - require:
      - sls: apache.install