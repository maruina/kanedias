{% from 'dkim/map.jinja' import dkim with context %}

dkim_create_conf_dir:
  file.directory:
    - name: {{ dkim.lookup.conf_dir }}
    - user: root
    - group: root
    - dir_mode: 644
    - recurse:
        - user
        - group
        - mode

dkim_create_keys_dir:
  file.directory:
    - name: {{ dkim.lookup.keys_dir }}
    - user: root
    - group: root
    - dir_mode: 644
    - recurse:
        - user
        - group
        - mode

dkim_conf:
  file.managed:
    - name: {{ dkim.lookup.conf_file }}
    - source: salt://dkim/files/opendkim.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: dkim_service

dkim_socket_conf:
  file.managed:
    - name: {{ dkim.lookup.socket_file }}
    - source: salt://dkim/files/opendkim
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: dkim_service

dkim_postfix_conf:
  cmd.script:
    - name: dkim_postfix.sh
    - source: salt://dkim/files/dkim_postfix.sh
    - user: root
    - group: root
    - template: jinja