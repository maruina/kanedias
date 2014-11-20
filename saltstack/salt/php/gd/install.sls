{% from 'php/map.jinja' import php with context %}

php_gd_install:
  pkg.installed:
    - name: {{ php.lookup.pkgs.gd }}
