{% from 'apache/map.jinja' import apache with context %}

{% if not apache.server.example_files %}
    {% if salt['grains.get']('os_family') == 'Debian' %}

apache_default_conf:
  file.absent:
    - name: {{ apache.lookup.sites_available }}/default

apache_default_conf_link:
  file.absent:
    - name: {{ apache.lookup.sites_enabled }}/000-default

apache_example_ssl_conf:
  file.absent:
    - name: {{ apache.lookup.sites_available }}/default-ssl

apache_example_ssl_conf_link:
  file.absent:
    - name: {{ apache.lookup.sites_enabled }}/default-ssl

    {% endif %}
{% endif %}

{% for name, parameters in salt['pillar.get']('apache:website').iteritems() %}
    {% set apache_conf_ssl = 'apache_conf_ssl_' ~ name %}
    {% set apache_conf = 'apache_conf_' ~ name %}
    {% if apache.lookup.vhost_use_symlink %}
        {% set apache_conf_ssl_enable = 'apache_conf_ssl_enable_' ~ name %}
        {% set apache_conf_enable = 'apache_conf_enable_' ~ name %}

{{ apache_conf_ssl }}:
  file.managed:
    - name: {{ apache.lookup.sites_available }}/{{ name }}-ssl.conf
    {% if parameters['type'] == 'webmail' %}
    - source: salt://apache/files/default-ssl-{{ salt['grains.get']('os_family') }}

    {% endif %}
    - user: root
    - group: root
    - mode: 622
    - template: jinja
    - watch_in:
      - service: apache_service
    - context:
        parameters: {{ parameters }}

{{ apache_conf_ssl_enable }}:
  file.symlink:
    - name: {{ apache.lookup.sites_enabled }}/{{ name }}-ssl.conf
    - target: {{ apache.lookup.sites_available }}/{{ name }}-ssl.conf
    - force: True
    - makedirs: True
    - watch_in:
      - service: apache_service

{{ apache_conf }}:
  file.managed:
    - name: {{ apache.lookup.sites_available }}/{{ name }}.conf
    {% if parameters['type'] == 'webmail' %}
    - source: salt://apache/files/default-{{ salt['grains.get']('os_family') }}
    {% endif %}
    - user: root
    - group: root
    - mode: 622
    - template: jinja
    - watch_in:
      - service: apache_service
    - context:
        parameters: {{ parameters }}

{{ apache_conf_enable }}:
  file.symlink:
    - name: {{ apache.lookup.sites_enabled }}/{{ name }}.conf
    - target: {{ apache.lookup.sites_available }}/{{ name }}.conf
    - force: True
    - makedirs: True
    - watch_in:
      - service: apache_service

    {% else %}

{{ apache_conf_ssl }}:
  file.managed:
    - name: {{ apache.lookup.sites_enabled }}/{{ name }}-ssl.conf
    {% if parameters['type'] == 'webmail' %}
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

{{ apache_conf }}:
  file.managed:
    - name: {{ apache.lookup.sites_enabled }}/{{ name }}.conf
    {% if parameters['type'] == 'webmail' %}
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
    {% if parameters['type'] == 'webmail' %}
        {% set apache_module_id = 'apache_module_' ~ parameters['type'] %}

{{ apache_module_id }}_conf:
  file.symlink:
    - name: {{ apache.lookup.mods_enabled }}/ssl.conf
    - target: {{ apache.lookup.mods_available }}/ssl.conf
    - force: True
    - makedirs: True
    - watch_in:
      - service: apache_service

{{ apache_module_id }}_load:
  file.symlink:
    - name: {{ apache.lookup.mods_enabled }}/ssl.load
    - target: {{ apache.lookup.mods_available }}/ssl.load
    - force: True
    - makedirs: True
    - watch_in:
      - service: apache_service

    {% endif %}
{% endfor %}