{% from 'php/map.jinja' import php with context %}

include:
  - php.cli.install

php_cli_service:
  service.running:
    - name: {{ php.lookup.fpm.service }}
    - enable: True
    - reload: True
    - require:
      - sls: php.cli.install
    - watch:
      - pgk: {{ php.lookup.pkgs.cli }}