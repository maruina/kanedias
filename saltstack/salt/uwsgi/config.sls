uwsgi_config:
  file.managed:
    - name: {{ salt['pillar.get']('uwsgi:conf_file') }}
    - source: salt://uwsgi/files/uwsgi.ini
    - makedirs: True
    - user: root
    - group: root
    - mode: 644
    - template: jinja

uwsgi_log_dir:
  file.directory:
    - name: {{ salt['pillar.get']('uwsgi:log_dir') }}
    - makedirs: True
    - user: {{ salt['pillar.get']('uwsgi:ini:uid') }}
    - group: {{ salt['pillar.get']('uwsgi:ini:gid') }}
    - mode: 644