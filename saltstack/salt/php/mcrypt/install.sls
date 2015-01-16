{% from 'php/map.jinja' import php with context %}

php_intl_install:
  pkg.installed:
    - name: {{ php.lookup.pkgs.intl }}
