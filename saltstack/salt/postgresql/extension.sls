{% from 'postgresql/map.jinja' import postgresql with context %}

{% for extension in salt['pillar.get']('postgresql:extension') %}
    {% for db in extension %}
    {% set extension_state_id = 'postgresql_extension_' ~ extension ~ '_' ~ db %}

{{ extension_state_id }}:
  postgres_extension.present:
    - name: {{ extension }}
    - maintenance_db: {{ db }}
    - require:
      - service: {{ postgresql.lookup.server_service }}

    {% endfor %}
{% endfor %}