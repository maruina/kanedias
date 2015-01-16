{% from 'roundcube/map.jinja' import roundcube with context %}

{% if not salt['pillar.get']('roundcube:install') %}

roundcube_delete_install_dir:
  file.absent:
    - name: {{ pillar['roundcube']['root_dir'] }}/installer

{% endif %}