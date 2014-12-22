{% from 'dovecot/map.jinja' import dovecot with context %}

dovecot_10_auth:
  file.managed:
    - name: {{ dovecot.lookup.confd_dir }}/10-auth.conf
    - source: salt://dovecot/files/10-auth.conf
    - user: root
    - group: root
    - mode: 622
    - replace: True
    - template: jinja

dovecot_auth_sql:
  file.managed:
    - name: {{ dovecot.lookup.confd_dir }}/auth-sql.conf.ext
    - source: salt://dovecot/files/auth-sql.conf.ext
    - user: root
    - group: root
    - mode: 622
    - replace: True
    - template: jinja

dovecot_10_mail:
  file.managed:
    - name: {{ dovecot.lookup.confd_dir }}/10-mail.conf
    - source: salt://dovecot/files/10-mail.conf
    - user: root
    - group: root
    - mode: 622
    - replace: True
    - template: jinja

dovecot_10_master:
  file.managed:
    - name: {{ dovecot.lookup.confd_dir }}/10-master.conf
    - source: salt://dovecot/files/10-master.conf
    - user: root
    - group: root
    - mode: 622
    - replace: True
    - template: jinja

dovecot_15_lda:
  file.managed:
    - name: {{ dovecot.lookup.confd_dir }}/15-lda.conf
    - source: salt://dovecot/files/15-lda.conf
    - user: root
    - group: root
    - mode: 622
    - replace: True
    - template: jinja
