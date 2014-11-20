{% from 'postfix/map.jinja' import postfix with context %}

{% if salt['grains.get']('os_family') == 'RedHat' %}
    {% if salt['grains.get']('os') == 'CentOS' %}
epel_centos_repo:
  pkg.installed:
    - name: epel-release
    {% endif %}
{% endif %}

postfix_install:
  pkg.installed:
    - name: {{ postfix.lookup.package }}