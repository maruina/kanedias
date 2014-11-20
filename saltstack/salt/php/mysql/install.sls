{% from 'php/map.jinja' import php with context %}

php_mysql_install:
  pkg.installed:
    - name: {{ php.lookup.pkgs.mysql }}
