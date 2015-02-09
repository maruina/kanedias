{% from 'asterisk/map.jinja' import asterisk with context %}

include:
  - asterisk.service

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

asterisk_modules:
  file.managed:
    - name: {{ asterisk.lookup.conf_dir }}/modules.conf
    - source: salt://asterisk/files/modules.conf
    - user: {{ asterisk.lookup.user }}
    - group: {{ asterisk.lookup.user }}
    - mode: 644
    - template: jinja
    - watch_in:
      - service: asterisk_service

asterisk_indications:
  file.managed:
    - name: {{ asterisk.lookup.conf_dir }}/indications.conf
    - source: salt://asterisk/files/indications.conf
    - user: {{ asterisk.lookup.user }}
    - group: {{ asterisk.lookup.user }}
    - mode: 644
    - template: jinja
    - watch_in:
      - service: asterisk_service

asterisk_sip:
  file.managed:
    - name: {{ asterisk.lookup.conf_dir }}/sip.conf
    - source: salt://asterisk/files/sip.conf
    - user: {{ asterisk.lookup.user }}
    - group: {{ asterisk.lookup.user }}
    - mode: 644
    - template: jinja
    - watch_in:
      - service: asterisk_service