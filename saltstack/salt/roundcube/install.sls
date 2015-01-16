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

roundcube_download:
  cmd.run:
    - name: wget http://downloads.sourceforge.net/project/roundcubemail/roundcubemail/1.0.4/roundcubemail-1.0.4.tar.gz -O roundcubemail.tar.gz
    - unless: test -f roundcubemail.tar

roundcue_extract:
  cmd.run:
    - name: gzip -d roundcubemail.tar.gz && tar -xf roundcubemail.tar --strip-components=1 -C {{ pillar['roundcube']['root_dir'] }}/ && touch /etc/roundcube.installed
    - unless: test -f /etc/roundcube.installed
