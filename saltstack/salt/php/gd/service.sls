{% from 'php/map.jinja' import php with context %}

include:
  - php.gd.install

php_gd_service:
  service.running:
    - name: {{ php.lookup.fpm.service }}
    - enable: True
    - reload: True
    - require:
      - sls: php.gd.install