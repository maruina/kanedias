{% from 'roundcube/map.jinja' import roundcube with context %}

roundcube_create_dir:
  file.directory:
    - name: {{ pillar['roundcube']['root_dir'] }}
    - user: {{ pillar['roundcube']['user'] }}
    - group: {{ pillar['roundcube']['group'] }}
    - dir_mode: 744
    - makedirs: True
    - recurse:
        - user
        - group
        - mode

roundcube_create_log_dir:
  file.directory:
    - name: /var/log/roundcube
    - user: {{ pillar['roundcube']['user'] }}
    - group: {{ pillar['roundcube']['group'] }}
    - dir_mode: 744
    - makedirs: True
    - recurse:
        - user
        - group
        - mode

roundcube_install:
  cmd.script:
    - name: install.sh
    - source: salt://roundcube/files/install.sh
    - user: root
    - group: root
    - template: jinja
