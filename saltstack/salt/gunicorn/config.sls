gunicorn_config:
  file.managed:
    - name: {{ salt['pillar.get']('gunicorn:conf_file') }}
    - source: salt://gunicorn/files/gunicorn.ini
    - user: {{ salt['pillar.get']('gunicorn:user') }}
    - group: {{ salt['pillar.get']('gunicorn:group') }}
    - mode: 644
    - template: jinja

gunicorn_log_dir:
  file.directory:
    - name: {{ salt['pillar.get']('gunicorn:log_dir') }}
    - makedirs: True
    - user: {{ salt['pillar.get']('gunicorn:user') }}
    - group: {{ salt['pillar.get']('gunicorn:group') }}
    - mode: 644