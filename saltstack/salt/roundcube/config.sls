{% if not salt['pillar.get']('roundcube:install') %}

roundcube_delete_install_dir:
  file.absent:
    - name: {{ salt['pillar.get']('roundcube:root_dir') }}/installer

{% endif %}

composer_config:
  file.managed:
    - name: {{ salt['pillar.get']('roundcube:root_dir') }}/composer.json
    - source: salt://roundcube/files/composer.json
    - user: {{ salt['pillar.get']('roundcube:user') }}
    - group: {{ salt['pillar.get']('roundcube:group') }}
    - mode: 744
    - template: jinja