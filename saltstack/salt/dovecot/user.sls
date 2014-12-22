{% from 'dovecot/map.jinja' import dovecot with context %}

dovecot_create_mail_group:
  group.present:
    - name: vmail

dovecot_create_mail_user:
  user.present:
    - name: {{ salt['pillar.get']('dovecot:vmail_user') }}
    - group: {{ salt['pillar.get']('dovecot:vmail_group') }}
    - fullname: Dovecot mail user
    - shell: /bin/false
    - home: {{ salt['pillar.get']('dovecot:vmail_dir') }}