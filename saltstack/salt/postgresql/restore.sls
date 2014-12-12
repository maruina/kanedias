{% from 'postgresql/map.jinja' import postgresql with context %}

{% if 'restore' in salt['pillar.get']('postgresql') %}
    {% for db, parameters in salt['pillar.get']('postgresql:restore').iteritems() %}
        {% set restore_file = 'restore_file_' ~ db %}
        {% set restore_db = 'restore_db_' ~ db %}

{{ restore_file }}:
  file.managed:
    - name: {{ parameters['file'] }}
    - source: salt://postgresql/files/{{ parameters['backup_name'] }}
    - user: postgres
    - group: postgres
    - mode: 700

{{ restore_db }}:
  cmd.wait:
    - name: psql {{ db }} < {{ parameters['file'] }}
    - user: {{ parameters['owner'] }}
    - watch:
      - file: {{ restore_file }}

    {% endfor %}
{% endif %}