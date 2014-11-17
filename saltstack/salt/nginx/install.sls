{% from 'nginx/map.jinja' import nginx with context %}

{% if salt['grains.get']('os_family') == 'RedHat' %}
{% if salt['grains.get']('os') == 'CentOS' %}
nginx_centos_repo:
  pkgrepo.managed:
    - name: nginx
    - humanname: nginx.repo
    - baseurl: http://nginx.org/packages/centos/{{ salt['grains.get']('osmajorrelease', '') }}/{{ salt['grains.get']('osarch', '') }}/
    - gpgcheck: 0
{% endif %}
{% endif %}

nginx_install:
  pkg.installed:
    - name: {{ nginx.lookup.package }}