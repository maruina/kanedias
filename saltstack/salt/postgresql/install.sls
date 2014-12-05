{% from 'postgresql/map.jinja' import postgresql with context %}

{% if salt['pillar.get']('postgresql:server:install') %}
    {% if salt['grains.get']('os_family') == 'RedHat' %}
        {% if salt['grains.get']('os') == 'CentOS' %}

postgresql_centos_repo:
  cmd.run:
    - name: rpm -ivh http://yum.postgresql.org/9.3/redhat/rhel-6-{{ salt['grains.get']('osarch') }}/pgdg-centos93-9.3-1.noarch.rpm
    - unlesse: ls /etc/yum.repos.d/ | grep pg

postgresql_server_init:
  cmd.run:
    - name: service postgresql-9.3 initdb
    - unless: test -f {{ postgres.conf_dir }}/postgresql.conf

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

postgis_install:
  pkg.installed:
    - name: {{ postgresql.lookup.postgis }}
    - require:
      - pkg: postgresql_server_install

        {% endif %}
    {% endif %}
{% endif %}