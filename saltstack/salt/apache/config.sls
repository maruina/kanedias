{% from 'apache/map.jinja' import apache with context %}

{% if not apache.server.example_files %}
    {% if salt['grains.get']('os') == 'CentOS' or salt['grains.get']('os_family') == 'Debian' %}

apache_default_conf:
  file.absent:
    - name: {{ apache.lookup.site_available }}/default.conf

apache_example_ssl_conf:
  file.absent:
    - name: {{ apache.lookup.vhost_available }}/default-ssl.conf

    {% endif %}
{% endif %}

{% for name, parameters in salt['pillar.get']('apache:website').iteritems() %}
    {% set apache_conf_id = 'apache_conf_' ~ name %}
    {% if apache.lookup.vhost_use_symlink %}
        {% set apache_conf_enable = 'apache_conf_enable_' ~ name %}

{{ apache_conf_id }}:
  file.managed:
    - name: {{ apache.lookup.site_available }}/{{ name }}.conf
    {% if parameters['type'] == 'ssl' %}
    - source: salt://apache/files/default-ssl-{{ salt['grains.get']('os_family') }}.conf
    {% endif %}
    - user: root
    - group: root
    - mode: 622
    - template: jinja
    - watch_in:
      - service: apache_service
    - context:
        parameters: {{ parameters }}

{{ apache_conf_enable }}
  file.symlink:
    - name: {{ apache.lookup.site_enable }}/{{ name }}.conf
    - target: {{ apache.lookup.site_available }}/{{ name }}.conf
    - force: True
    - makedirs: True

    {% else %}

{{ apache_conf_id }}:
  file.managed:
    - name: {{ apache.lookup.site_enable }}/{{ name }}.conf
    {% if parameters['type'] == 'ssl' %}
    - source: salt://apache/files/default-ssl-{{ salt['grains.get']('os_family') }}.conf
    {% endif %}
    - user: root
    - group: root
    - mode: 622
    - template: jinja
    - watch_in:
      - service: apache_service
    - context:
        parameters: {{ parameters }}

    {% endif %}
{% endfor %}