{% from 'php/map.jinja' import php with context %}

php_ini_config:
  file.managed:
    - name: {{ php.lookup.fpm.ini }}
    - source: salt://php/fpm/files/php.ini
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: {{ php.lookup.fpm.service }}


{% for pool, parameters in salt['pillar.get']('php:fpm').iteritems() %}
  {% set pool_conf_id = 'fpm_pool_conf_' ~ pool %}

{{ pool_conf_id }}:
  file.managed:
    - name: {{ php.lookup.fpm.pool_dir }}/{{ pool }}.conf
    - source: salt://php/fpm/files/pool.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: {{ php.lookup.fpm.service }}
    - context:
        pool: {{ pool }}
        parameters: {{ parameters }}

{% endfor %}