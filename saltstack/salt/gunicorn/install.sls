{% if 'miniconda' in salt['pillar.get']('gunicorn') %}
gunicorn_install:
  cmd.run:
    - name: {{ salt['pillar.get']('gunicorn:virtualenv') }}/bin/conda install -n {{ salt['pillar.get']('gunicorn:miniconda:virtualenv_name') }} gunicorn
    - unless: test -f {{ salt['pillar.get']('gunicorn:virtualenv') }}/bin/gunicorn

  {% if 'sync' not in salt['pillar.get']('gunicorn:worker_class') %}

gunicorn_install_worker_class:
  cmd.run:
    - name: {{ salt['pillar.get']('gunicorn:virtualenv') }}/bin/conda install -n {{ salt['pillar.get']('gunicorn:miniconda:virtualenv_name') }} {{ salt['pillar.get']('gunicorn:worker_class') }}
    - unless: test -f {{ salt['pillar.get']('gunicorn:virtualenv') }}/bin/{{ salt['pillar.get']('gunicorn:worker_class') }}

  {% endif %}
{% else %}
  {# TODO: install gunicorn from pip #}
{% endif %}