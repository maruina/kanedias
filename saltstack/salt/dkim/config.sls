{% from 'dkim/map.jinja' import dkim with context %}

include:
  - dkim.install

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
    - name: {{ dkim.lookup.keys_dir }}/{{ salt['pillar.get']('dkim:domain') }}
    - user: {{ dkim.lookup.user }}
    - group: {{ dkim.lookup.group }}
    - dir_mode: 644
    - makedirs: True
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
    - require:
      - file: dkim_create_conf_dir


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
    - require:
      - file: dkim_create_conf_dir

dkim_postfix_conf:
  cmd.script:
    - name: dkim_postfix.sh
    - source: salt://dkim/files/dkim_postfix.sh
    - user: root
    - group: root
    - template: jinja

dkim_trusted_host:
  file.managed:
    - name: {{ dkim.lookup.conf_dir }}/TrustedHosts
    - source: salt://dkim/files/TrustedHosts
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: dkim_service
    - require:
      - file: dkim_create_conf_dir

dkim_key_table:
  file.managed:
    - name: {{ dkim.lookup.conf_dir }}/KeyTable
    - source: salt://dkim/files/KeyTable
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: dkim_service
    - require:
      - file: dkim_create_conf_dir

dkim_signing_table:
  file.managed:
    - name: {{ dkim.lookup.conf_dir }}/SigningTable
    - source: salt://dkim/files/SigningTable
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - watch_in:
      - service: dkim_service
    - require:
      - file: dkim_create_conf_dir

dkim_create_keys:
  cmd.run:
    - name: opendkim-genkey -s {{ salt['pillar.get']('dkim:selector') }} -d {{ salt['pillar.get']('dkim:domain') }}
    - unless: test -f {{ dkim.lookup.keys_dir }}/{{ salt['pillar.get']('dkim:domain') }}/{{ salt['pillar.get']('dkim:selector') }}.private
    - cwd: {{ dkim.lookup.keys_dir }}/{{ salt['pillar.get']('dkim:domain') }}
    - watch_in:
      - service: dkim_service
    - require:
      - file: dkim_create_keys_dir
      - sls: dkim.install