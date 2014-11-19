{% from 'php/map.jinja' import php with context %}

php_fpm_install:
  pkg.installed:
    - name: {{ php.lookup.pkgs.fpm }}
