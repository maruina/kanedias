{% from 'ntp/map.jinja' import ntp with context %}

include:
  - ntp.install

ntp_service:
  service.running:
    - name: {{ ntp.lookup.service }}
    - enable: True
    - reload: True
    - require:
      - sls: nginx.install