gunicorn_install_latest:
  cmd.run:
    {% if salt['pillar.get']('gunicorn:virtualenv') %}
    - name: {{ salt['pillar.get']('gunicorn:virtualenv') }}/bin/pip install gunicorn
    {% else %}
    - name: pip install gunicorn
    {% endif %}