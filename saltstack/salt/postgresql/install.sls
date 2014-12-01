{% from 'postgresql/map.jinja' import postgresql with context %}

{% if salt['pillar.get']('postgresql:server:install') %}
    {% if salt['grains.get']('os_family') == 'RedHat' %}
        {% if salt['grains.get']('os') == 'CentOS' %}

postgresql_server_install:
  pkg.installed:
    - pkgs:
      - {{ postgresql.lookup.server }}
      - {{ postgresql.lookup.contrib }}
      - {{ postgresql.lookup.devel }}

        {% endif %}
    {% endif %}
{% endif %}

{% if salt['pillar.get']('postgresql:server:postgis') %}
    {% if salt['grains.get']('os_family') == 'RedHat' %}
        {% if salt['grains.get']('os') == 'CentOS' %}

postgis_centos_repo:
  pkgrepo.managed:
    - name: postgis
    - humanname: postgis.repo
    - baseurl: http://yum.postgresql.org/9.3/redhat/rhel-6-{{ salt['grains.get']('osarch', '') }}/pgdg-centos93-9.3-1.noarch.rpm
    - gpgcheck: 0

postgis_install:
  pkg.installed:
    - name: {{ postgresql.lookup.postgis }}
    - require:
      - pkg: postgresql_server_install

        {% endif %}
    {% endif %}
{% endif %}