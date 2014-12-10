gunicorn_install:
  cmd.run:
    - name: {{ salt['pillar.get']('gunicorn:virtualenv') }}/bin/pip install gunicorn
    - unless: test -f {{ salt['pillar.get']('gunicorn:virtualenv') }}/bin/gunicorn

{% if 'sync' not in salt['pillar.get']('gunicorn:worker_class') %}

gunicorn_install_worker_class:
  cmd.run:
    - name: {{ salt['pillar.get']('gunicorn:virtualenv') }}/bin/pip install {{ salt['pillar.get']('gunicorn:worker_class') }}
    - unless: test -f {{ salt['pillar.get']('gunicorn:virtualenv') }}/bin/{{ salt['pillar.get']('gunicorn:worker_class') }}

{% endif %}