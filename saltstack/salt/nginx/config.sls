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