gunicorn_config:
  file.managed:
    - name: {{ salt['pillar.get']('gunicorn:conf_file') }}
    - source: salt://gunicorn/files/gunicorn.ini
    - user: root
    - group: root
    - mode: 644
    - template: jinja

uwsgi_log_dir:
  file.directory:
    - name: {{ salt['pillar.get']('gunicorn:log_dir') }}
    - makedirs: True
    - user: {{ salt['pillar.get']('gunicorn:uid') }}
    - group: {{ salt['pillar.get']('gunicorn:gid') }}
    - mode: 644