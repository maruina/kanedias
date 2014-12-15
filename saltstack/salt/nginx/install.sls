{% from 'nginx/map.jinja' import nginx with context %}

{% if 'nginx' in salt['pillar.get']('nginx:server:source') %}
  {% if salt['grains.get']('os_family') == 'RedHat' %}
    {% if salt['grains.get']('os') == 'CentOS' %}

nginx_centos_repo:
  pkgrepo.managed:
    - name: nginx
    - humanname: nginx.repo
    - baseurl: http://nginx.org/packages/centos/{{ salt['grains.get']('osmajorrelease', '') }}/{{ salt['grains.get']('osarch', '') }}/
    - gpgcheck: 0

    {% endif %}
  {% elif salt['grains.get']('os_family') == 'Debian' %}

nginx_debian_repo:
  pkgrepo.managed:
    - humanname: Nignx
    - name: deb http://nginx.org/packages/debian/ wheezy nginx
    - file: /etc/apt/sources.list.d/nginx.list
    - key_url: http://nginx.org/keys/nginx_signing.key

nginx_debian_repo_src:
  pkgrepo.managed:
    - humanname: Nignx src
    - name: deb-src http://nginx.org/packages/debian/ wheezy nginx
    - file: /etc/apt/sources.list.d/nginx_src.list
    - key_url: http://nginx.org/keys/nginx_signing.key

  {% endif %}
{% endif %}

nginx_install:
  pkg.installed:
    - name: {{ nginx.lookup.package }}