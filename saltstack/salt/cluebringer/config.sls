{% from 'cluebringer/map.jinja' import cluebringer with context %}

cluebringer_mysql_conf:
  cmd.run:
    - name: zcat /usr/share/doc/postfix-cluebringer/database/policyd-db.mysql.gz | sed -e 's/TYPE=InnoDB/ENGINE=InnoDB/' | mysql --user={{ salt['pillar.get']('cluebringer:db:user') }} --password={{ salt['pillar.get']('cluebringer:db:password') }} {{ salt['pillar.get']('cluebringer:db:database') }} && touch {{ cluebringer.lookup.conf_dir }}/mysql_db.installed
    - unless: test -f {{ cluebringer.lookup.conf_dir }}/mysql_db.installed

cluebringer_conf:
  file.managed:
    - name: {{ cluebringer.lookup.conf_file }}
    - source: salt://cluebringer/files/cluebringer.conf
    - user: {{ cluebringer.lookup.user }}
    - group: {{ cluebringer.lookup.group }}
    - mode: 640
    - template: jinja
    - watch_in:
      - service: cluebringer_service
    - require:
      - cmd: cluebringer_mysql_conf