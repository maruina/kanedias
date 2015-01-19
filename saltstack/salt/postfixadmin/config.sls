{#{% if not salt['pillar.get']('postfixadmin:install') %}#}
{##}
{#postfixadmin_delete_install_dir:#}
{#  file.absent:#}
{#    - name: {{ salt['pillar.get']('postfixadmin:root_dir') }}/installer#}
{##}
{#{% endif %}#}
