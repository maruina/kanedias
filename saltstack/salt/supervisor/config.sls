{% from 'supervisor/map.jinja' import supervisor with context %}

supervisor_conf_file:
  file.managed:
    - name: {{ supervisor.lookup.conf_file }}
    - source: salt://supervisor/files/supervisor.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: {{ supervisor.lookup.service }}