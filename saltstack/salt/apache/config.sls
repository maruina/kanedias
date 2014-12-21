{% from 'apache/map.jinja' import apache with context %}

{% for name, parameters in salt['pillar.get']('apache:website').iteritems() %}
  {% set apache_conf_id = 'apache_conf_' ~ name %}

{{ apache_conf_id }}:
  file.managed:
    - name: {{ apache.lookup.vhost_enabled }}/{{ name }}.conf
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
      - service: nginx_service
    - context:
        parameters: {{ parameters }}