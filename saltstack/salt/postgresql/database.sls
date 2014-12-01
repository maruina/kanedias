{% from 'postgresql/map.jinja' import postgresql with context %}

{% for name, parameter in salt['pillar.get']('postgresql:database').iteritems() %}
{% set extension_state_id = 'postgresql_database_' ~ name %}
{{ extension_state_id }}:
  postgres_database.present:
    - name: {{ name }}
    - owner: {{ parameter['owner'] }}
    - lc_collate: {{ parameter['lc_collate'] }}
    - lc_ctype: {{ parameter['lc_ctype'] }}


{% endfor %}