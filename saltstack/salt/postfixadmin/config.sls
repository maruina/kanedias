{#postfixadmin_config:#}
{#  cmd.script:#}
{#    - name: config.sh#}
{#    - source: salt://postfixadmin/files/config.sh#}
{#    - cwd: {{ salt['pillar.get']('postfixadmin:root_dir') }}#}
{#    - user: root#}
{#    - group: root#}
{#    - template: jinja#}