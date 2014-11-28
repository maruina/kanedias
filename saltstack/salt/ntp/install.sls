{% from 'ntp/map.jinja' import ntp with context %}

{% if salt['grains.get']('os_family') == 'RedHat' %}
ntp_install:
  pkg.installed:
    - name: {{ ntp.lookup.package }}
{% endif %}