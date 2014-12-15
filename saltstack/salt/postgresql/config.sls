{% from 'postgresql/map.jinja' import postgresql with context %}

pg_hba_conf:
  file.managed:
    - name: {{ postgresql.lookup.conf_dir }}/pg_hba.conf
    - source: salt://postgresql/files/pg_hba-{{ salt['grains.get']('os_family') }}.conf
    - user: postgres
    - group: postgres
    - mode: 600
    - template: jinja
    - watch_in:
      - service: {{ postgresql.lookup.server_service }}

postgresql_conf:
  file.managed:
    - name: {{ postgresql.lookup.conf_dir }}/postgresql.conf
    - source: salt://postgresql/files/postgresql-{{ salt['grains.get']('os_family') }}.conf
    - user: postgres
    - group: postgres
    - mode: 600
    - template: jinja
    - watch_in:
      - service: {{ postgresql.lookup.server_service }}