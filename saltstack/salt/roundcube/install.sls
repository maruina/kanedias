{% from 'roundcube/map.jinja' import roundcube with context %}

{% if salt['grains.get']('os_family') == 'RedHat' %}
    {% if salt['grains.get']('os') == 'CentOS' %}
epel_centos_repo:
  pkg.installed:
    - name: epel-release
    {% endif %}
{% endif %}

roundecube_install:
  pkg.installed:
    - pkgs:
      - {{ roundcube.lookup.package }}
      - {{ roundcube.lookup.plugins }}