{% from 'nginx/map.jinja' import nginx with context %}

include:
  - nginx.install

nginx_service:
  service.running:
    - name: {{ nginx.lookup.service }}
    - enable: True
    - reload: True
    - watch:
      - pkg: {{ nginx.lookup.package }}
    - require:
      - sls: nginx.install