{% from 'postgresql/map.jinja' import postgresql with context %}

pg_hba_conf:
  file.managed:
    - name: {{ nginx.lookup.conf_dir }}/pg_hba.conf
    - source: salt://postgresql/files/pg_hba.conf
    - user: postgres
    - group: postgres
    - mode: 700
    - template: jinja
    - watch_in:
      - service: {{ postgresql.lookup.server_service }}