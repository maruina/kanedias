{% from 'dovecot/map.jinja' import dovecot with context %}

include:
  - dovecot.user

{% if 'verified' in salt['pillar.get']('dovecot:ssl_type') %}

postfix_create_key_dir:
  file.directory:
    - name: {{ dovecot.lookup.conf_dir }}/ssl
    - user: root
    - group: root
    - dir_mode: 700
    - makedirs: True
    - recurse:
        - user
        - group
        - mode

postfix_install_crt:
  file.managed:
    - name: {{ dovecot.lookup.conf_dir }}/ssl/{{ salt['pillar.get']('dovecot:fqdn') }}.crt
    - source: salt://dovecot/files/ssl.crt
    - user: root
    - group: root
    - mode: 600
    - template: jinja

postfix_install_key:
  file.managed:
    - name: {{ dovecot.lookup.conf_dir }}/ssl/{{ salt['pillar.get']('dovecot:fqdn') }}.key
    - source: salt://dovecot/files/ssl.key
    - user: root
    - group: root
    - mode: 600
    - template: jinja

{% endif %}



dovecot_10_auth:
  file.managed:
    - name: {{ dovecot.lookup.confd_dir }}/10-auth.conf
    - source: salt://dovecot/files/10-auth.conf
    - user: root
    - group: root
    - mode: 644
    - replace: True
    - template: jinja

dovecot_auth_sql:
  file.managed:
    - name: {{ dovecot.lookup.confd_dir }}/auth-sql.conf.ext
    - source: salt://dovecot/files/auth-sql.conf.ext
    - user: root
    - group: root
    - mode: 644
    - replace: True
    - template: jinja

dovecot_10_mail:
  file.managed:
    - name: {{ dovecot.lookup.confd_dir }}/10-mail.conf
    - source: salt://dovecot/files/10-mail.conf
    - user: root
    - group: root
    - mode: 644
    - replace: True
    - template: jinja

dovecot_10_master:
  file.managed:
    - name: {{ dovecot.lookup.confd_dir }}/10-master.conf
    - source: salt://dovecot/files/10-master.conf
    - user: root
    - group: root
    - mode: 644
    - replace: True
    - template: jinja

dovecot_10_ssl:
  file.managed:
    - name: {{ dovecot.lookup.confd_dir }}/10-ssl.conf
    - source: salt://dovecot/files/10-ssl.conf
    - user: root
    - group: root
    - mode: 644
    - replace: True
    - template: jinja
    - context:
        ssl_dir: {{ dovecot.lookup.conf_dir }}/ssl

dovecot_15_lda:
  file.managed:
    - name: {{ dovecot.lookup.confd_dir }}/15-lda.conf
    - source: salt://dovecot/files/15-lda.conf
    - user: root
    - group: root
    - mode: 644
    - replace: True
    - template: jinja

dovecot_sql_conf:
  file.managed:
    - name: {{ dovecot.lookup.conf_dir }}/dovecot-sql.conf.ext
    - source: salt://dovecot/files/dovecot-sql.conf.ext
    - user: root
    - group: root
    - mode: 644
    - replace: True
    - template: jinja

dovecot_conf:
  file.managed:
    - name: {{ dovecot.lookup.conf_dir }}/dovecot.conf
    - user: root
    - group: root
    - mode: 644
    - watch_in:
      - service: dovecot_service
    - require:
      - sls: dovecot.user
