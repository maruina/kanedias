{% from 'php/map.jinja' import php with context %}

php_imap_install:
  pkg.installed:
    - name: {{ php.lookup.pkgs.imap }}
