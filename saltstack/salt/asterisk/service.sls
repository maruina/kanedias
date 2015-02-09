{% from 'asterisk/map.jinja' import asterisk with context %}

include:
  - asterisk.install

asterisk_service:
  service.running:
    - name: {{ asterisk.lookup.service }}
    - enable: True
    - reload: True
    - require:
      - sls: asterisk.install