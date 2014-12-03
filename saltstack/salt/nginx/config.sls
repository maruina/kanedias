{% from 'nginx/map.jinja' import nginx with context %}

{% if not nginx.server.example_files %}
    {% if salt['grains.get']('os') == 'CentOS' %}

nginx_default_conf:
  file.absent:
    - name: {{ nginx.lookup.vhost_enabled }}/default.conf

nginx_example_ssl_conf:
  file.absent:
    - name: {{ nginx.lookup.vhost_enabled }}/example_ssl.conf
    {% endif %}
{% endif %}

{% for website, parameters in salt['pillar.get']('nginx:website') %}
  {% set nginx_conf_id = 'nginx_conf_' ~ website %}

{{ nginx_conf_id }}:
  file.managed:
    - name: {{ nginx.lookup.vhost_enabled }}/{{ website }}.conf
    {% if parameters['type'] == 'php' %}
    - source: salt://nginx/files/php_host.conf
    {% elif parameters['type'] == 'python' %}
    - source: salt://nginx/files/php_host.conf
    {% endif %}
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: {{ nginx.lookup.service }}

{% endfor %}
