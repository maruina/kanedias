{% from 'php/map.jinja' import php with context %}

php_ini_config:
  file.managed:
    - name: {{ php.fpm.ini }}
    - source: salt://php/fpm/files/php.ini
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: {{ php.fpm.service }}

php_fpm_confd_www_config:
  file.managed:
    - name: {{ php.fpm.www }}
    - source: salt://php/fpm/files/www.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: {{ php.fpm.service }}