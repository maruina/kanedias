{% from 'supervisor/map.jinja' import supervisor with context %}

supervisor_user:
  user.present:
    - name: {{ salt['pillar.get']('supervisor:user') }}
    - shell: /bin/false
    - createhome: False
    - gid_from_name: True

supervisor_conf_file:
  file.managed:
    - name: {{ supervisor.lookup.conf_file }}
    - source: salt://supervisor/files/supervisord.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: {{ supervisor.lookup.service }}