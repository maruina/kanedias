{% from 'postfix/map.jinja' import postfix with context %}

include:
  - postfix.install

postfix_service:
  service.running:
    - name: {{ postfix.lookup.service }}
    - enable: True
    - reload: True
    - require:
      - sls: postfix.install