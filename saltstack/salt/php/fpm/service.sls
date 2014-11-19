{% from 'php/map.jinja' import php with context %}

include:
  - php.fpm.install

php_fpm_service:
  service.running:
    - name: {{ php.fpm.service }}
    - enable: True
    - reload: True
    - require:
      - sls: php.fpm.install