{% from 'sqlgrey/map.jinja' import sqlgrey with context %}

sqlgrey_conf:
  file.managed:
    - name: {{ sqlgrey.lookup.conf_file }}
    - source: salt://sqlgrey/files/sqlgrey.conf
    - user: {{ sqlgrey.lookup.user }}
    - group: {{ sqlgrey.lookup.group }}
    - mode: 660
    - template: jinja
    - watch_in:
      - service: sqlgrey_service

sqlgrey_postfix_conf:
  cmd.script:
    - name: sqlgrey_postfix.sh
    - source: salt://sqlgrey/files/sqlgrey_postfix.sh
    - user: root
    - group: root
    - template: jinja