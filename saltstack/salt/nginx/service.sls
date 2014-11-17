{% from 'nginx/map.jinja' import nginx with context %}

include:
  - ngnix.install

nginx_service:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - pkg: {{ nginx.lookup.package }}
    - require:
      - sls: nginx.install