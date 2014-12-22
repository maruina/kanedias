{% from 'dovecot/map.jinja' import dovecot with context %}

dovecot_create_mail_group:
  group.present:
    - name: vmail

dovecot_create_mail_user:
  user.present:
    - name: vmail
    - group: vmail
    - fullname: Dovecot mail user
    - shell: /bin/false
    - home: {{ salt['pillar.get']('dovecot:vmail_dir') }}