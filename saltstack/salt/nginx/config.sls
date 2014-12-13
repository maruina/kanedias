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

{% for name, parameters in salt['pillar.get']('nginx:website').iteritems() %}
  {% set nginx_conf_id = 'nginx_conf_' ~ name %}

{{ nginx_conf_id }}:
  file.managed:
    - name: {{ nginx.lookup.vhost_enabled }}/{{ name }}.conf
    {% if parameters['type'] == 'php' %}
    - source: salt://nginx/files/php_host.conf
    {% elif parameters['type'] == 'python' %}
    - source: salt://nginx/files/python_host.conf
    {% endif %}
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: {{ nginx.lookup.service }}
    - context:
        parameters: {{ parameters }}

  {% if 'htaccess' in parameters %}
      {% if parameters['htaccess']['enable'] %}
        {% set htpwd_pkg = 'htpwd_pkg_' ~ name %}
        {% set htacc_file = 'htpwd_file_' ~ name %}

{{ htpwd_pkg }}:
  pkg.installed:
    - name: {{ nginx.lookup.apache_utils }}

{{ htacc_file }}:
  file.managed:
    - name: {{ parameters['hpasswd']['file'] }}
    - user: nginx
    - group: nginx
    - mode: 644

        {% for user, password in parameters['htaccess']['user'].iteritems() %}
          {% set htpwd_id = 'htpwd_' ~ user %}

{{ htpwd_id }}:
  cmd.run:
    - name: htpasswd -db {{ parameters['htaccess']['file'] }} {{ user }} {{ password }}

        {% endfor %}
      {% else %}

{{ htacc_file }}:
  file.absent:
    - name: {{ parameters['hpasswd']['file'] }}

      {% endif %}

  {% endif %}

{% endfor %}
