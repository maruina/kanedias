{% from 'postgresql/map.jinja' import postgresql with context %}

{% for extension, dbs in salt['pillar.get']('postgresql:extension').iteritems() %}
    {% for db in dbs %}
    {% set extension_state_id = 'extension_' ~ extension ~ '_' ~ db %}

{{ extension_state_id }}:
  postgres_extension.present:
    - name: {{ extension }}
    - maintenance_db: {{ db }}
    - require:
      - service: {{ postgresql.lookup.server_service }}

    {% endfor %}
{% endfor %}