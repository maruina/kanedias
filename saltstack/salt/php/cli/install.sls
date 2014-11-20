{% from 'php/map.jinja' import php with context %}

php_cli_install:
  pkg.installed:
    - name: {{ php.lookup.pkgs.cli }}
