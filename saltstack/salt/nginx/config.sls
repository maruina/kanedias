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

{% if salt['pillar.get']('nginx:website:type') == 'php' %}
      nginx_website_conf:
        file.managed:
          - name: {{ nginx.lookup.vhost_enabled }}/{{ salt['pillar.get']('nginx:website:name') }}.conf
          - source: salt://nginx/files/php_host.conf
          - user: root
          - group: root
          - mode: 644
          - template: jinja
          - watch_in:
            - service: {{ nginx.lookup.service }}
{% endif %}
