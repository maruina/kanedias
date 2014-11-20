{% from 'php/map.jinja' import php with context %}

include:
  - php.mysql.install

php_mysql_service:
  service.running:
    - name: {{ php.lookup.fpm.service }}
    - enable: True
    - reload: True
    - require:
      - sls: php.mysql.install