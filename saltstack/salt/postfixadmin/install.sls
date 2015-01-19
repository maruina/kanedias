postfixadmin_create_dir:
  file.directory:
    - name: {{ salt['pillar.get']('postfixadmin:root_dir') }}
    - user: {{ salt['pillar.get']('postfixadmin:user') }}
    - group: {{ salt['pillar.get']('postfixadmin:group') }}
    - dir_mode: 744
    - makedirs: True
    - recurse:
        - user
        - group
        - mode

{#postfix_create_log_dir:#}
{#  file.directory:#}
{#    - name: /var/log/postfix#}
{#    - user: {{ salt['pillar.get']('postfix:user') }}#}
{#    - group: {{ salt['pillar.get']('postfixadmin:group') }}#}
{#    - dir_mode: 744#}
{#    - makedirs: True#}
{#    - recurse:#}
{#        - user#}
{#        - group#}
{#        - mode#}

postfixadmin_install:
  cmd.script:
    - name: install.sh
    - source: salt://postfixadmin/files/install.sh
    - user: root
    - group: root
    - template: jinja
