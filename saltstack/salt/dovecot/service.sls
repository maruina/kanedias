{% from 'dovecot/map.jinja' import dovecot with context %}

include:
  - dovecot.install

dovecot_service:
  service.running:
    - name: {{ dovecot.lookup.service }}
    - enable: True
    - reload: True
    - require:
      - sls: dovecot.install