{% from 'nginx/map.jinja' import nginx with context %}

{% if 'nginx' in salt['pillar.get']('nginx:server:source') %}
  {% if not nginx.server.example_files %}

nginx_default_conf:
  file.absent:
    - name: {{ nginx.lookup.confd_dir }}/default.conf

nginx_example_ssl_conf:
  file.absent:
    - name: {{ nginx.lookup.confd_dir }}/example_ssl.conf

  {% else %}
      {# Add rename of example files #}
  {% endif %}
{% else %}
    {# Handle nginx installed from official repository #}
{% endif %}

{% for name, parameters in salt['pillar.get']('nginx:website').iteritems() %}
  {% set nginx_conf_id = 'nginx_conf_' ~ name %}

{{ nginx_conf_id }}:
  file.managed:
    - name: {{ nginx.lookup.confd_dir }}/{{ name }}.conf
    {% if parameters['type'] == 'php' %}
    - source: salt://nginx/files/php_host.conf
    {% elif parameters['type'] == 'python' %}
    - source: salt://nginx/files/python_host.conf
    {% elif parameters['type'] == 'roundcube' %}
    - source: salt://nginx/files/roundcube-{{ salt['grains.get']('os_family') }}.conf
    {% elif parameters['type'] == 'postfixadmin' %}
    - source: salt://nginx/files/postfixadmin-{{ salt['grains.get']('os_family') }}.conf
    {% endif %}
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: nginx_service
    - context:
        parameters: {{ parameters }}

  {% if 'htaccess' in parameters %}
    {% set htacc_file = 'htpwd_file_' ~ name %}
    {% if parameters['htaccess']['enable'] %}
      {% set htpwd_pkg = 'htpwd_pkg_' ~ name %}

{{ htpwd_pkg }}:
  pkg.installed:
    - name: {{ nginx.lookup.apache_utils }}

{{ htacc_file }}:
  file.managed:
    - name: {{ parameters['htaccess']['file'] }}
    - user: {{ nginx.lookup.webuser }}
    - group: {{ nginx.lookup.webuser }}
    - replace: False
    - mode: 600

      {% for user, password in parameters['htaccess']['user'].iteritems() %}
        {% set htpwd_id = 'htpwd_' ~ user %}

{{ htpwd_id }}:
  cmd.run:
    - name: htpasswd -mb {{ parameters['htaccess']['file'] }} {{ user }} {{ password }}

      {% endfor %}
    {% else %}

{{ htacc_file }}:
  file.absent:
    - name: {{ parameters['htaccess']['file'] }}

    {% endif %}
  {% endif %}
{% endfor %}
