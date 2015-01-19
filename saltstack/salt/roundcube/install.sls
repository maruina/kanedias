roundcube_create_dir:
  file.directory:
    - name: {{ salt['pillar.get']('roundcube:root_dir') }}
    - user: {{ salt['pillar.get']('roundcube:user') }}
    - group: {{ salt['pillar.get']('roundcube:group') }}
    - dir_mode: 744
    - makedirs: True
    - recurse:
        - user
        - group
        - mode

roundcube_create_log_dir:
  file.directory:
    - name: /var/log/roundcube
    - user: {{ salt['pillar.get']('roundcube:user') }}
    - group: {{ salt['pillar.get']('roundcube:group') }}
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
