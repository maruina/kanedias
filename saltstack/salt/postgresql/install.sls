{% from 'postgresql/map.jinja' import postgresql with context %}

{% if salt['pillar.get']('postgresql:server:install') %}
    {% if salt['grains.get']('os_family') == 'RedHat' %}
        {% if salt['grains.get']('os') == 'CentOS' %}

postgresql_centos_repo:
  cmd.run:
    - name: rpm -ivh http://yum.postgresql.org/9.3/redhat/rhel-6-{{ salt['grains.get']('osarch') }}/pgdg-centos93-9.3-1.noarch.rpm
    - unless: ls /etc/yum.repos.d/ | grep pg

epel_repo:
  cmd.run:
    - name: yum install epel-release

        {% endif %}
    {% elif salt['grains.get']('os_family') == 'Debian' %}

postgresql_debian_repo:
  pkgrepo.managed:
    - humanname: Postgis PPA
    - name: deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main
    - file: /etc/apt/sources.list.d/postgis.list
    - key_url: http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc

    {% endif %}

postgresql_server_install:
  pkg.installed:
    - pkgs:
      - {{ postgresql.lookup.server }}
      - {{ postgresql.lookup.contrib }}
      - {{ postgresql.lookup.devel }}
      - {{ postgresql.lookup.python }}

{#    {% if salt['grains.get']('os_family') == 'RedHat' %}#}
{#        {% if salt['grains.get']('os') == 'CentOS' %}#}
{##}
{#postgresql_server_init:#}
{#  cmd.run:#}
{#    - name: service postgresql-9.3 initdb#}
{#    - unless: test -f {{ postgresql.lookup.conf_dir }}/postgresql.conf#}
{##}
{#        {% endif %}#}
{#    {% endif %}#}
{% endif %}

postgresql_path:
  file.managed:
    - name: {{ postgresql.lookup.profile_dir }}/postgresql.sh
    - source: salt://postgresql/files/postgresql.sh
    - user: root
    - group: root
    - mode: 644

{% if salt['pillar.get']('postgresql:server:postgis') %}

postgis_install:
  pkg.installed:
    - name: {{ postgresql.lookup.postgis }}
    - require:
      - pkg: postgresql_server_install

{% endif %}