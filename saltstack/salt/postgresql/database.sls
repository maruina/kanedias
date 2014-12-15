{% from 'postgresql/map.jinja' import postgresql with context %}

include:
  - postgresql.user

{% for name, parameter in salt['pillar.get']('postgresql:database').iteritems() %}
{% set extension_state_id = 'postgresql_database_' ~ name %}
{{ extension_state_id }}:
  postgres_database.present:
    - name: {{ name }}
    - owner: {{ parameter['owner'] }}
    {% if 'lc_collate' in parameter %}
    - lc_collate: {{ parameter['lc_collate'] }}
    {% endif %}
    {% if 'lc_ctype' in parameter %}
    - lc_ctype: {{ parameter['lc_ctype'] }}
    {% endif %}
    - template: template0
    - require:
      - sls: postgresql.user

{% endfor %}