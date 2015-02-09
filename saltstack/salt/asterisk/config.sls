{% from 'asterisk/map.jinja' import asterisk with context %}

asterisk_create_dir:
  file.directory:
    - name: {{ asterisk.lookup.conf_dir }}
    - user: {{ asterisk.lookup.user }}
    - group: {{ asterisk.lookup.user }}
    - dir_mode: 744
    - makedirs: True
    - recurse:
        - user
        - group
        - mode

asterisk_conf:
  file.managed:
    - name: {{ asterisk.lookup.conf_dir }}/asterisk.conf
    - source: salt://asterisk/files/asterisk.conf
    - user: {{ asterisk.lookup.user }}
    - group: {{ asterisk.lookup.user }}
    - mode: 644
    - template: jinja
    - watch_in:
      - service: asterisk_service