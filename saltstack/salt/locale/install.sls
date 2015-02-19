{% from 'locale/map.jinja' import locale with context %}

lc_ctype_install:
  file.managed:
    - name: {{ locale.lookup.profile_dir }}/locale.sh
    - source: salt://locale/files/locale.sh
    - user: root
    - group: root
    - mode: 755