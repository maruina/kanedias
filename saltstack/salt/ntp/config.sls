{% from 'ntp/map.jinja' import ntp with context %}

ntp_conf:
  file.managed:
    - name: {{ ntp.lookup.conf_file }}
    - source: salt://ntp/files/ntp.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: ntp_service

timezone_set:
  timezone.system:
    - name: {{ salt['pillar.get']('ntp:timezone') }}
    - utc: {{ salt['pillar.get']('ntp:utc') }}