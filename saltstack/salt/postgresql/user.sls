{% from 'postgresql/map.jinja' import postgresql with context %}

{% for name, user in salt['pillar.get']('postgresql:user', {}).items() %}
{% set user_state_id = 'postgresql_user_' ~ name %}

{{ user_state_id }}:
  postgres_group.present:
    - name: {{ name }}
    - password: {{ user.password }}
    - require:
      - service: {{ postgresql.lookup.server_service }}

{% endfor %}