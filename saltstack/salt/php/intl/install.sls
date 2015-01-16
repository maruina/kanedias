{% from 'php/map.jinja' import php with context %}

php_mcrypt_install:
  pkg.installed:
    - name: {{ php.lookup.pkgs.mcrypt }}
