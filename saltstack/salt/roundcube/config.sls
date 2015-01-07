{% from 'roundcube/map.jinja' import roundcube with context %}

{% if salt['grains.get']('os') == 'Debian' %}

debian_db_php:
  file.managed:
    - name: {{ roundcube.lookup.conf_dir }}/debian-db.php
    - source: salt://roundcube/files/debian-db.php
    - user: {{ roundcube.lookup.user }}
    - group: {{ roundcube.lookup.group }}
    - mode: 644
    - template: jinja

{% endif %}