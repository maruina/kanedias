{% from 'mysql/map.jinja' import mysql with context %}

{% if salt['pillar.get']('mysql:server:install') %}
    mysql_server_install:
      pkg.install:
        - name: {{ mysql.lookup.server }}

    mysql_python_install:
      pkg.install:
        - name: {{ mysql.lookup.python }}
{% endif %}
